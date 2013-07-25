public class ScorecardTestingUtils
{
	public static Map<String, Map<String, RecordType>> recordTypes
	{
		get
		{
			if( recordTypes == null )
			{
				recordTypes = new Map<String, Map<String, RecordType>>();
			}
			return recordTypes;
		}
		private set;
	}

	public static RecordType findRecordType( String sObjectAPIName, String developerName )
	{
		if( !recordTypes.containsKey( sObjectAPIName ) )
		{
			List<RecordType> types = [Select Id, DeveloperName from RecordType where sObjectType = :sObjectAPIName];
			recordTypes.put( sObjectAPIName, new Map<String, RecordType>() );
			for(RecordType r : types)
			{
				recordTypes.get( sObjectAPIName ).put( r.DeveloperName, r );
			}
		}
		try
		{
			return recordTypes.get( sObjectAPIName ).get( developerName );
		}
		catch(Exception e)
		{
			throw new UnknownRecordTypeException('The record type could not be found.  Does the object exist? Does the developer name exist?' + 
                                                 'sObject Type: ' + sObjectAPIName + ' Developer Name: ' + developerName);
		}
	}
	public class UnknownRecordTypeException extends Exception {}

	public static Row__c createRow( Id scorecardId, String aliasName, Boolean doInsert )
	{
		Row__c r = new Row__c( Name='', Alias__c=aliasName, Scorecard__c=scorecardId );
		if( doInsert ) insert r;
		return r;
	}

	public static Field__c createField( Id rowId, Id queryGroupId, Id recordTypeId, String apiName, Boolean doInsert )
	{
		Field__c field = new Field__c( Row__c=rowId, QueryGroup__c=queryGroupId, RecordTypeId=recordTypeId, API_Name__c=apiName );
		if( doInsert ) insert field;
		return field;
	}

	public static Field__c createField( Id rowId, Id queryGroupId, Id recordTypeId, String apiName, String condition, Boolean doInsert)
	{
		Field__c field = createField( rowId, queryGroupId, recordTypeId, apiName, false );
		field.Condition__c = condition;
		if( doInsert ) insert field;
		return field;
	}
}