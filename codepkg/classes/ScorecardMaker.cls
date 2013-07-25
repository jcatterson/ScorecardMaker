public class ScorecardMaker
{
	public String scorecardDetails {get; set;}
	private Id scorecardId;
	public ScorecardMaker()
	{
		scorecardId = ApexPages.currentPage().getParameters().get(ScorecardJSONDriver.SCORECARD_META_ID);
		if( scorecardId != null )
		{
			Document itemsDocument = [SELECT Id, Body FROM Document WHERE Id = :scorecardId];
			scorecardDetails = itemsDocument.Body.toString();
		}
	}

	public PageReference save()
	{
		System.debug( scorecardDetails );
		Document d = MobileProductPickerServices.generateTextDocument( 'myScorecard', Blob.valueOf(scorecardDetails) );
		if( scorecardId != null )
			d.Id = scorecardId;
		upsert d;
		PageReference pg = Page.ScorecardDisplay;
		pg.getParameters().put(ScorecardJSONDriver.SCORECARD_META_ID, d.Id );
		return pg;
	}
}