// src/config/google.ts
import { google } from 'googleapis';
import { OAuth2Client } from 'google-auth-library';

interface AlarmData {
  time: string;
  date: string;
  repeat: boolean;
  days: string[];
  label: string;
}

export async function criarEventoAlarme(auth: OAuth2Client, alarm: AlarmData) {
  const calendar = google.calendar({ version: 'v3', auth });

  const startDateTime = new Date(`${alarm.date}T${alarm.time}:00`);
  const endDateTime = new Date(startDateTime.getTime() + 15 * 60 * 1000); // 15 min

  const event = {
    summary: alarm.label || 'Alarme Aloy',
    start: {
      dateTime: startDateTime.toISOString(),
      timeZone: 'America/Sao_Paulo',
    },
    end: {
      dateTime: endDateTime.toISOString(),
      timeZone: 'America/Sao_Paulo',
    },
    reminders: {
      useDefault: false,
      overrides: [
        { method: 'popup', minutes: 0 }, // dispara na hora
      ],
    },
    recurrence: alarm.repeat
      ? [`RRULE:FREQ=WEEKLY;BYDAY=${alarm.days.join(',')}`]
      : undefined,
  };

  const response = await calendar.events.insert({
    calendarId: 'primary',
    requestBody: event,
  });

  console.log('📆 Evento criado:', response.data.htmlLink);
}
