import { criarEventoAlarme } from './config/google';
import { loadSavedCredentialsIfExist } from './config/googleAuth';
import { getRabbitMQConfig } from './config/rabbitmq';
import * as amqp from 'amqplib';

const bootstrap = async () => {
  const auth = await loadSavedCredentialsIfExist();

  const rabbitmqConfig = getRabbitMQConfig();
  const connection = await amqp.connect(rabbitmqConfig);
  const channel = await connection.createChannel();

  await channel.assertQueue('set_alarm', { durable: true });

  channel.consume('set_alarm', async (msg) => {
    if (msg !== null) {
      const content = msg.content.toString();
      console.log(`📨 Mensagem recebida: ${content}`);

      try {
        // Safely parse the message content
        const alarmData = content.trim() === '' ? null : 
          Function('return ' + content)();
        
        if (!alarmData) {
          throw new Error('Invalid alarm data received');
        }

        await criarEventoAlarme(auth, alarmData);
        channel.ack(msg);
      } catch (err) {
        console.error('❌ Erro ao criar evento:', err);
        channel.nack(msg, false, false);
      }
    }
  });

  console.log('🚀 Aloy Scheduler rodando e ouvindo o RabbitMQ...');
};

bootstrap();
