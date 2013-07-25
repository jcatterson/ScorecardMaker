public class ScorecardJSONDriver
{
	public Scorecard sc {get; private set;}
	public static final String SCORECARD_META_ID = 'id';
	public ScorecardJSONDriver()
	{
		Id doc = ApexPages.currentPage().getParameters().get(SCORECARD_META_ID);
		Document itemsDocument = [SELECT Id, Body FROM Document WHERE Id = :doc];
		String jsonStr = itemsDocument.Body.toString();
		sc = (Scorecard)JSON.deserialize( jsonStr, Scorecard.class );
		sc.run();
	}
}