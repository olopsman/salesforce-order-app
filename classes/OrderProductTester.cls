@isTest
private class OrderProductTester {
	
	@isTest static void testRedirect() {
		Account acc = new Account();
		acc.Name = 'ACME';
		insert acc;

		Order ord = new Order(); 
		ord.AccountId = acc.Id;
		ord.EffectiveDate = date.today();
		ord.Status = 'Draft';
		insert ord;
		// Implement test code
		PageReference pageRef = Page.orderProductRedirect;
		ApexPages.currentPage().getParameters().put('id', ord.Id);
		Test.setCurrentPageReference(pageRef);
		ApexPages.StandardController sc = new ApexPages.StandardController(ord);		
		OrderProductRedirectExtension ordCon = new OrderProductRedirectExtension(sc);
        System.assert(ordCon.redirect()!=null);		
	}
	
	@isTest static void testOrderSelection() {
		// Implement test code
		Account acc = new Account();
		acc.Name = 'ACME';
		insert acc;

		//create products
		Product2 prod = new Product2();
		prod.Name = 'Consumables';
		insert prod;
		
		//get pricebook
		Id pricebookId = Test.getStandardPricebookId();
		PriceBookEntry standardPrice = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = prod.Id,
			unitprice = 100,
			isActive = true
		);
		insert standardPrice;

		//create a new pricebook to satisfy query
		PriceBook2 pb = new PriceBook2(Name='Custom PB', isActive=true);
		insert pb;

		PriceBook2 stPb = new PriceBook2(Id=pricebookId, Name='Standard Price Book', isActive=true);
		update stPb;

		//create pricebookentry
		PriceBookEntry customPrice = new PricebookEntry(
			Pricebook2Id = pb.Id,
			Product2Id = prod.Id,
			unitprice = 100,
			isActive = true
			);
		insert customPrice;

		Order ord = new Order(); 
		ord.AccountId = acc.Id;
		ord.EffectiveDate = date.today();
		ord.Status = 'Draft';
		ord.Pricebook2Id = stPb.Id;
		insert ord;

		//create existing orderItem
		OrderItem ordItem = new OrderItem();
		ordItem.OrderId = ord.Id;
		ordItem.quantity = 1;
		ordItem.PricebookEntryId = standardPrice.Id;
		ordItem.unitprice = 100;
		insert ordItem;
                
        ////////////////////////////////////////
        //  test opportunityProductEntry
        ////////////////////////////////////////
        Test.startTest();
        // load the page       
        PageReference pageRef = Page.orderProductEntry;
        pageRef.getParameters().put('id',ord.Id);
        Test.setCurrentPageReference(pageRef);
        
		ApexPages.StandardController sc = new ApexPages.StandardController(ord);		
		OrderProductEntryExtension oPEE = new OrderProductEntryExtension(sc);

        // test 'getChosenCurrency' method
        if(UserInfo.isMultiCurrencyOrganization())
            System.assert(oPEE.getChosenCurrency()!='');
        else
            System.assertEquals(oPEE.getChosenCurrency(),'');

        // we know that there is at least one line item, so we confirm
        Integer startCount = oPEE.ShoppingCart.size();
        system.assert(startCount>0);

        //test search functionality without finding anything
        oPEE.searchString = 'Consumables';
        oPEE.updateAvailableList();
        system.assert(oPEE.AvailableProducts.size()==0);
        
        //test remove from shopping cart
        oPEE.toUnselect = ordItem.PricebookEntryId;
        oPEE.removeFromShoppingCart();
        system.assert(oPEE.shoppingCart.size()==startCount-1);
        
        //test save and reload extension
        oPEE.onSave();
        oPEE = new orderProductEntryExtension(sc);
        system.assert(oPEE.shoppingCart.size()==startCount-1);
        
        // test search again, this time we will find something
        oPEE.searchString = ordItem.PricebookEntry.Name;
        oPEE.updateAvailableList();
        system.assert(oPEE.AvailableProducts.size()>0);       

        // test add to Shopping Cart function
        oPEE.toSelect = oPEE.AvailableProducts[0].Id;
        oPEE.addToShoppingCart();
        system.assert(oPEE.shoppingCart.size()==startCount);
                
        // test save method - WITHOUT quanitities and amounts entered and confirm that error message is displayed
        oPEE.onSave();
        system.assert(ApexPages.getMessages().size()>0);
        
        // add required info and try save again
        for(OrderItem o : oPEE.ShoppingCart){
            o.quantity = 5;
            o.unitprice = 300;
        }
        oPEE.onSave();
        
        // query line items to confirm that the save worked
        orderItem[] oli2 = [select Id from OrderItem where OrderId = :ord.Id];
        system.assert(oli2.size()==startCount);
        
        Test.stopTest();

        // test on new Opp (no pricebook selected) to make sure redirect is happening
        Order newOpp = new Order(
        		Name='New Opp',EffectiveDate=date.today(),
        		AccountId=acc.Id, Status='Draft');
        insert(newOpp);
        

        ApexPages.StandardController newSc = new ApexPages.StandardController(newOpp);
        oPEE = new orderProductEntryExtension(newSc);
        
        System.assert(oPEE.priceBookCheck()!=null);
        
        // final quick check of cancel button
        System.assert(oPEE.onCancel()!=null);
        
	}
	
}