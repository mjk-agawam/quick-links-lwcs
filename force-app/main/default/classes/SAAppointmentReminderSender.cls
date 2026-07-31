/**
 * Sends a 24-hour appointment reminder email + mock SMS for a ServiceAppointment.
 * Called from the SA_AppointmentReminder scheduled flow.
 */
public with sharing class SAAppointmentReminderSender {

    private static final String DEMO_RECIPIENT = 'mikeknight@salesforce.com';

    public class Request {
        @InvocableVariable(required=true label='Service Appointment Id')
        public Id serviceAppointmentId;
    }

    @InvocableMethod(label='Send Appointment Reminder (Email + Mock SMS)'
        description='Sends a 24-hour reminder email and a mock SMS email to the demo inbox')
    public static void send(List<Request> requests) {
        Set<Id> saIds = new Set<Id>();
        for (Request r : requests) {
            if (r.serviceAppointmentId != null) saIds.add(r.serviceAppointmentId);
        }
        if (saIds.isEmpty()) return;

        List<ServiceAppointment> sas = [
            SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime,
                   ContactId, Contact.FirstName, Contact.Name, Contact.MobilePhone,
                   ServiceTerritory.Name, WorkType.Name, Street, City, State
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (ServiceAppointment sa : sas) {
            if (sa.ContactId == null) continue;

            String apptDate = sa.SchedStartTime != null
                ? sa.SchedStartTime.format('EEEE, MMMM d \'at\' h:mm a z')
                : 'your upcoming appointment';
            String firstName = sa.Contact.FirstName != null ? sa.Contact.FirstName : sa.Contact.Name;
            String location = buildLocation(sa);
            String workType = sa.WorkType != null ? sa.WorkType.Name : 'your appointment';

            // Email reminder
            emails.add(buildEmailReminder(sa, firstName, apptDate, location, workType));

            // Mock SMS (plain text email styled as a text)
            emails.add(buildMockSms(sa, firstName, apptDate, sa.Contact.MobilePhone));
        }

        if (!emails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emails);
        }
    }

    private static Messaging.SingleEmailMessage buildEmailReminder(
        ServiceAppointment sa, String firstName, String apptDate, String location, String workType
    ) {
        String subject = 'Reminder: Your appointment is tomorrow';
        String body = '<html><body style="font-family:sans-serif;color:#333;">'
            + '<h2 style="color:#0070d2;">Appointment Reminder</h2>'
            + '<p>Hi ' + firstName + ',</p>'
            + '<p>This is a reminder that your <strong>' + workType + '</strong> appointment is scheduled for:</p>'
            + '<p style="font-size:16px;font-weight:bold;color:#0070d2;">' + apptDate + '</p>'
            + (String.isNotBlank(location) ? '<p>Location: ' + location + '</p>' : '')
            + '<p>Appointment #: ' + sa.AppointmentNumber + '</p>'
            + '<p>If you need to reschedule or cancel, please use the link in your original confirmation email.</p>'
            + '<p>We look forward to seeing you!</p>'
            + '</body></html>';

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setTargetObjectId(sa.ContactId);
        msg.setTreatTargetObjectAsRecipient(false);
        msg.setToAddresses(new List<String>{ DEMO_RECIPIENT });
        msg.setSubject(subject);
        msg.setHtmlBody(body);
        msg.setSaveAsActivity(false);
        return msg;
    }

    private static Messaging.SingleEmailMessage buildMockSms(
        ServiceAppointment sa, String firstName, String apptDate, String mobilePhone
    ) {
        String toNumber = String.isNotBlank(mobilePhone) ? mobilePhone : 'unknown';
        String smsText = 'Hi ' + firstName + ', reminder: your appointment is tomorrow, '
            + apptDate + '. Appt #' + sa.AppointmentNumber
            + '. Reply STOP to unsubscribe. [MOCK SMS — would send to ' + toNumber + ']';

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setTargetObjectId(sa.ContactId);
        msg.setTreatTargetObjectAsRecipient(false);
        msg.setToAddresses(new List<String>{ DEMO_RECIPIENT });
        msg.setSubject('[MOCK SMS to ' + toNumber + '] Appointment Reminder');
        msg.setPlainTextBody(smsText);
        msg.setSaveAsActivity(false);
        return msg;
    }

    private static String buildLocation(ServiceAppointment sa) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(sa.Street)) parts.add(sa.Street);
        if (String.isNotBlank(sa.City)) parts.add(sa.City);
        if (String.isNotBlank(sa.State)) parts.add(sa.State);
        return String.join(parts, ', ');
    }
}
