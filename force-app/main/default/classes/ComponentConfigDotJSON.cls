public with sharing class ComponentConfigDotJSON {
        public String name;
        public String description;
        public String author;
        public String authorEmail;
        public String alias;
        public String packageType;
        public String permissionSet;
        public Boolean disableSourceInstall;             
        public Boolean disablePackageInstall;
        public List<map<string,string>> dependencies;
        public String errorFlag;
        public String errorMessage;   
    
    public ComponentConfigDotJSON() {

    }
}
