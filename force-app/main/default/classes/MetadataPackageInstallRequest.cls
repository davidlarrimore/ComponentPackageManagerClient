
    public with sharing  class MetadataPackageInstallRequest {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<MetadataPackageInstallRequestRecord> records;
        
        public MetadataPackageInstallRequest() {
    
        }
    }    