global class PackageManagerScheduledJob implements Schedulable {
    global void execute(SchedulableContext SC) {
        VersionHelper.getInstalledPackages();
     }
}
