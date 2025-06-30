import * as amqp from 'amqplib';
import { getRabbitMQConfig } from './config/rabbitmq';

const message = {
  time: "07:00",
  date: "2025-04-18",
  repeat: false,
  days: [],
  label: "Acordar pra dominar o mundo"
};

async function sendMessage() {
  const rabbitmqConfig = getRabbitMQConfig();
  const connection = await amqp.connect(rabbitmqConfig);
  const channel = await connection.createChannel();

  await channel.assertQueue('set_alarm', { durable: true });
  
  channel.sendToQueue('set_alarm', Buffer.from(JSON.stringify(message)));
  console.log("✅ Message sent!");

  setTimeout(() => {
    connection.close();
    process.exit(0);
  }, 500);
}

sendMessage().catch(console.error);