public class JobPhaseAppointmentCreator {

    public class Request {
        @InvocableVariable(required=true)  public Id     jobId;
        @InvocableVariable(required=true)  public String eventName;
        @InvocableVariable(required=true)  public Date   startDate;
        @InvocableVariable(required=true)  public Date   endDate;
        @InvocableVariable(required=true)  public Id     workTypeLoadIn;
        @InvocableVariable(required=true)  public Id     workTypeShowDay;
        @InvocableVariable(required=true)  public Id     workTypeLoadOut;
        @InvocableVariable                 public Id     accountId;
        @InvocableVariable                 public Id     territoryId;
    }

    @InvocableMethod(label='Create Phase Appointments' description='Creates Load-In, Show Day (one per day), and Load-Out SAs for a Job.')
    public static void createPhaseAppointments(List<Request> requests) {
        List<ServiceAppointment> toInsert = new List<ServiceAppointment>();

        for (Request req : requests) {
            if (req.accountId == null) continue;

            // Load-In — start date
            toInsert.add(buildSA(req, req.startDate, req.eventName + ' - Load-In',
                req.workTypeLoadIn, 13, 21));

            // Show Day — one per day from startDate+1 through endDate-1
            Date showDay = req.startDate.addDays(1);
            Date loadOutDay = req.endDate;
            while (showDay < loadOutDay) {
                String dayLabel = Datetime.newInstance(showDay, Time.newInstance(0,0,0,0))
                                         .format('MMM d');
                toInsert.add(buildSA(req, showDay,
                    req.eventName + ' - Show Day (' + dayLabel + ')',
                    req.workTypeShowDay, 13, 21));
                showDay = showDay.addDays(1);
            }

            // Load-Out — end date
            toInsert.add(buildSA(req, req.endDate, req.eventName + ' - Load-Out',
                req.workTypeLoadOut, 13, 21));
        }

        insert toInsert;
    }

    private static ServiceAppointment buildSA(Request req, Date d, String subject,
                                               Id workTypeId, Integer startHour, Integer endHour) {
        ServiceAppointment sa = new ServiceAppointment();
        sa.Subject             = subject;
        sa.Job__c              = req.jobId;
        sa.ParentRecordId      = req.accountId;
        sa.WorkTypeId          = workTypeId;
        sa.ServiceTerritoryId  = req.territoryId;
        sa.EarliestStartTime   = Datetime.newInstance(d, Time.newInstance(startHour, 0, 0, 0));
        sa.DueDate             = Datetime.newInstance(d, Time.newInstance(endHour,   0, 0, 0));
        sa.Duration            = 480;
        sa.DurationType        = 'Minutes';
        sa.Status              = 'None';
        return sa;
    }
}
