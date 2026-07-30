public class CrewCallSheetSender {

    public class Request {
        @InvocableVariable(required=true) public Id serviceAppointmentId;
    }

    @InvocableMethod(label='Send Crew Call Sheet' description='Emails a call sheet to all assigned crew for a Service Appointment.')
    public static void sendCallSheet(List<Request> requests) {
        for (Request req : requests) {
            sendForAppointment(req.serviceAppointmentId);
        }
    }

    private static void sendForAppointment(Id saId) {
        ServiceAppointment sa = [
            SELECT Id, Subject, SchedStartTime, SchedEndTime, EarliestStartTime, DueDate,
                   Status, WorkType.Name, ServiceTerritory.Name,
                   Job__r.Event_Name__c, Job__r.Venue__c,
                   Job__r.Account__r.Name,
                   Crew_Required__c,
                   (SELECT ServiceResource.Name, ServiceResource.RelatedRecordId
                    FROM ServiceResources)
            FROM ServiceAppointment
            WHERE Id = :saId
            LIMIT 1
        ];

        // Collect email addresses of human crew (Type=T resources with a linked User/Contact)
        List<String> toAddresses = new List<String>();
        List<String> crewNames   = new List<String>();
        for (AssignedResource ar : sa.ServiceResources) {
            crewNames.add(ar.ServiceResource.Name);
            if (ar.ServiceResource.RelatedRecordId != null) {
                String rid = ar.ServiceResource.RelatedRecordId;
                String prefix = rid.substring(0, 3);
                if (prefix == '005') {
                    // It's a User
                    User u = [SELECT Email FROM User WHERE Id = :ar.ServiceResource.RelatedRecordId LIMIT 1];
                    if (String.isNotBlank(u.Email)) toAddresses.add(u.Email);
                }
            }
        }

        if (toAddresses.isEmpty()) return; // no emailable crew

        Datetime startTime = sa.SchedStartTime != null ? sa.SchedStartTime : sa.EarliestStartTime;
        Datetime endTime   = sa.SchedEndTime   != null ? sa.SchedEndTime   : sa.DueDate;

        String venue      = sa.Job__r != null && sa.Job__r.Venue__c != null ? sa.Job__r.Venue__c : 'TBD';
        String eventName  = sa.Job__r != null ? sa.Job__r.Event_Name__c : sa.Subject;
        String client     = sa.Job__r != null && sa.Job__r.Account__r != null ? sa.Job__r.Account__r.Name : '';
        String territory  = sa.ServiceTerritory != null ? sa.ServiceTerritory.Name : '';
        String workType   = sa.WorkType != null ? sa.WorkType.Name : '';
        Integer required  = sa.Crew_Required__c != null ? (Integer)sa.Crew_Required__c : 0;

        String startStr = startTime != null ? startTime.format('EEE, MMM d yyyy h:mm a z') : 'TBD';
        String endStr   = endTime   != null ? endTime.format('h:mm a z')                   : 'TBD';
        String crewList = String.join(crewNames, ', ');

        String subject = 'Crew Call Sheet: ' + sa.Subject;

        String body = 'CREW CALL SHEET\n'
            + '=====================================\n'
            + 'Event:       ' + eventName + '\n'
            + 'Client:      ' + client + '\n'
            + 'Venue:       ' + venue + '\n'
            + 'Territory:   ' + territory + '\n'
            + '\n'
            + 'SHIFT DETAILS\n'
            + '-------------------------------------\n'
            + 'Phase:       ' + sa.Subject + '\n'
            + 'Work Type:   ' + workType + '\n'
            + 'Report Time: ' + startStr + '\n'
            + 'End Time:    ' + endStr + '\n'
            + 'Status:      ' + sa.Status + '\n'
            + '\n'
            + 'CREW ASSIGNED (' + crewNames.size() + (required > 0 ? '/' + required : '') + ')\n'
            + '-------------------------------------\n'
            + crewList + '\n'
            + '\n'
            + 'Please reply to confirm receipt of this call sheet.\n'
            + '\n'
            + 'Shepherd Event Services\n';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}
