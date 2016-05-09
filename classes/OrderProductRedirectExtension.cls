public with sharing class OrderProductRedirectExtension {

	Id ordId;

    // we are extending the OpportunityLineItem controller, so we query to get the parent OpportunityId
    public orderProductRedirectExtension(ApexPages.StandardController controller) {
        //List<OrderItem> ordList = [select Id, OrderId from OrderItem where Id = :controller.getRecord().Id limit 1];
        //if(ordList.size() > 0)
        	ordId = controller.getRecord().Id;

    }
    
    // then we redirect to our desired page with the Opportunity Id in the URL
    public pageReference redirect(){
        return new PageReference('/apex/orderProductEntry?id=' + ordId);
    }

}