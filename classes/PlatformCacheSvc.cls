public class PlatformCacheSvc {

    public static String    DEFAULT_NAMESPACE   = 'local';
    public static Integer   MAX_TTL_SECS        = 172800; // 48 hours

    /**
     * @param nameSpace  The namespace of the org partition (By default local).
     * @param partition  The partition name (i.e. geotab).
     * @param key        A case-sensitive string value that uniquely identifies a cached value.
     * @param value      The value to store in the cache. The cached value must be serializable.
     * @param ttlSecs    The amount of time, in seconds, to keep the cached value in the cache.
     * @param visibility Indicates whether the cached value is available only to Apex code that is executing in the
     *                   same namespace or to Apex code executing from any namespace.
     * @param immutable  Indicates whether the cached value can be overwritten by another namespace (false) or not (true).
     */
    public static void saveInOrg(   String nameSpace,String partition,String key,Object value, Integer ttlSecs,
                                    Cache.Visibility visibility, Boolean immutable) {

        String qualifiedKey = nameSpace+'.'+partition +'.'+key;
        Cache.Org.put(qualifiedKey,value,ttlSecs,visibility,immutable);
    }

    /**
     * @param partition The partition name (i.e. geotab).
     * @param key       A case-sensitive string value that uniquely identifies a cached value.
     * @param value     The value to store in the cache. The cached value must be serializable.
     */
    public static void saveInOrg(String partition, String key, Object value) {
        saveInOrg(DEFAULT_NAMESPACE,partition,key,value,MAX_TTL_SECS,Cache.Visibility.NAMESPACE,true);
    }

    /**
     * @param partition The partition name (i.e. geotab).
     * @param key       A case-sensitive string value that uniquely identifies a cached value.
     *
     * @return          The value in the cache.
     */
    public static Object retrieveFromOrg(String partition,String key) {

        Cache.OrgPartition orgPartition = getOrgPartition(partition);
        Object obj = orgPartition.get(key);
        return obj;
    }

    /**
     * @param partition The partition name (i.e. geotab).
     * @return          The Cache.OrgPartition value.
     */
    public static Cache.OrgPartition getOrgPartition(String partition) {

        String partitionName = DEFAULT_NAMESPACE+'.'+partition;
        return Cache.Org.getPartition(partitionName);
    }

    /**
     * @param devName  The developerName of the PlatformCachePartition sObj.
     * @return         A single Platform Cache sObj.
     */
    public static PlatformCachePartition retrievePcPartition(String devName) {
        PlatformCachePartition partition;

        List<PlatformCachePartition> partitions = [
                SELECT Id,DeveloperName,Description
                FROM   PlatformCachePartition
                WHERE  DeveloperName = :devName
        ];
        partition = !partitions.isEmpty() ? partitions[0] : null;
        return partition;
    }

}