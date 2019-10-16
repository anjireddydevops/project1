/**
* @author Incapsulate
* @description : CPT_CaseHelper, this is Helper class for Case Object.
*/ 
public class CPT_CaseHelper 
{
    public static final String PORTAL_USER_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CPT_Constants.caseRecordType).getRecordTypeId();
    public static final String Generic_Contact = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(CPT_Constants.contactRecordType).getRecordTypeId();
    public static Boolean recursive = false;
    
    /**
    * @description This Method will create new Contact and update case with new contact Id.
    * @param newCases List of New Cases that are created from the Public Page Form.
    */ 
   /* public static void createContact(List<Case> newCases) 
    {
        Map<Case,Contact> caseContactMap = new Map<Case,Contact>();
        for(Case cas : newCases)
        {
            if(cas.ContactId == null && cas.CPT_Contact_Last_Name__c!=null && cas.RecordTypeId == PORTAL_USER_RECORDTYPE )
            {
                Contact newContact = new Contact(RecordTypeId = Generic_Contact,
                                                 LastName = cas.CPT_Contact_Last_Name__c,
                                                 FirstName=cas.CPT_Contact_First_Name__c,
                                                 Email = cas.CPT_Contact_Email__c,
                                                 Department=cas.CPT_Contact_Department__c,
                                                 Phone=cas.CPT_Contact_Phone_Number__c,
                                                 Salutation=cas.CPT_Contact_Salutation__c,
                                                 AccountId=cas.AccountId,
                                                 CPT_Constituent_ID__c = cas.CPT_Contact_Constituent_ID__c
                                                 
                );
                caseContactMap.put(cas,newContact);
            }
        }
        system.debug('caseContactMap-->'+caseContactMap);
        if(!caseContactMap.isEmpty())
        {    
            insert caseContactMap.values();   //Inserting the Contact(s)
            for(Case cs : caseContactMap.keySet())
            {    
                cs.ContactId = caseContactMap.get(cs).Id; //updating the Case contact Id
            }
        }
        
        
    }*/
    //Before Insert
    public static void preProccesing(List<Case> cases)
    {
        for(Case cs : cases)
        {
            if(CPT_CaseRecordType.check(cs.RecordTypeId)){
                if(cs.CPT_Form_AccountId__c != null)
                {
                    cs.AccountId = cs.CPT_Form_AccountId__c;
                }
            }
        }
    }
    
     /**
    * @description This Method will update Transaction Template and Transaction Template Version.
    * @param newCases List of New Cases.
    **/ 
    
    public static void updateTemplateInfo(Map<Id,Case> oldMap, Map<Id,Case> newMap, String context) 
    {
        if(!recursive)
        {
            recursive = true;
            system.debug('Entering here in updatetempinfo...>>>');
            
            Set<ID> TransactionTypeIds = new Set<ID>();
            Map<ID,ILPB__Certificate_Transaction_Association__c> TransTypeCTAMap = new Map<ID,ILPB__Certificate_Transaction_Association__c>();
            Map<ID,Boolean> CaseSubmittedMap = new Map<ID,Boolean>();
            Map<ID,Boolean> CaseDraftMap = new Map<ID,Boolean>();
            Boolean SubmittedStep = FALSE;
            List<Case> newCases = [SELECT ID,CaseNumber,ILPB__Transaction_Type__c,OwnerId,CPT_Form_AccountId__c,CPT_Form_TransactionType_ID__c,CPT_Form_Intake_Status__c,AccountId,RecordTypeId,
                                          ILPB__Transaction_Template__c, ILPB__Transaction_Type_Template_Version__c,ILPB__Transaction_Lifecycle_Step__c,Status,
                                          ILPB__Transaction_SubStatus__c, ILPB__Form_Intake__c, ILPB__Date_Time_Submitted__c, ILPB__Form_Intake__r.CreatedById, ILPB__Form_Intake__r.CreatedBy.ContactId,
                                          CreatedBy.ContactId, Account.Name, ILPB__Form_Intake__r.CPT_Account__c, ILPB__Submitter__c, ILPB__Form_Intake__r.CPT_Account__r.Name, Account.CPT_Chair_Person__c , 
                                          Account.CPT_Chairperson_Email__c,Account.CPT_Certificate_related__c, Account.CPT_Chair_Person__r.FirstName, Account.CPT_Chair_Person__r.LastName, Account.CPT_Chair_Person__r.Email, 
                                          ILPB__Form_Intake__r.CPT_Account__r.CPT_Chairperson_Email__c,ILPB__Form_Intake__r.CPT_Account__r.CPT_Certificate_related__c, CPT_Chairperson_Attribute__c 
                                  FROM Case 
                                  WHERE ID IN:newMap.values()];
            
               system.debug('>>>>>>>>>88>>>>>>>>'+newCases);
             
            for(Case cs:newCases)
            {    
                
                if(context=='insert' || (context=='update' &&  cs.ILPB__Date_Time_Submitted__c==null &&
                                         CPT_CaseRecordType.check(cs.RecordTypeId)
                                        ))
                    
                {

                
                    cs.ContactId = cs.Account.CPT_Chair_Person__c;
                    cs.Chairperson_Email__c = cs.Account.CPT_Chairperson_Email__c;//cs.ILPB__Form_Intake__r.CPT_Account__r.CPT_Chairperson_Email__c; //This should be a formula field from Account
                    
                    if(cs.Account.CPT_Certificate_related__c!=null)
                    {
                        cs.AssetId = cs.Account.CPT_Certificate_related__c;
                       
                    }
               
                
                    
                system.debug('>>>>70>>herein>>> ');
                if(cs.ILPB__Transaction_Type__c!=null || cs.CPT_Form_TransactionType_ID__c!=null) //check if ILPB__Transaction_Type__c or CPT_Form_TransactionType_ID__c is null or not
                {
                    if(cs.CPT_Form_TransactionType_ID__c!=null) //if CPT_Form_TransactionType_ID__c is not null i;e its coming from Form, then fill in the ILPB__Transaction_Type__c
                    {   
                        cs.ILPB__Transaction_Type__c = cs.CPT_Form_TransactionType_ID__c ;
                    }
                    TransactionTypeIds.add(cs.ILPB__Transaction_Type__c); //collect the Transaction Type IDs      
                    //System.assertEquals(1,2,TransactionTypeIds);
                    system.debug('>>>81>>>>>'+cs.CPT_Form_Intake_Status__c );
                    
                    if(cs.CPT_Form_Intake_Status__c == null && context == 'insert')
                    {
                        CaseSubmittedMap.put(cs.Id,TRUE);
                    }
                    else if(cs.CPT_Form_Intake_Status__c=='Submitted')//&& old_intake_status!=current_intake_status //check if the Case if Submitted or not
                    {
                        CaseSubmittedMap.put(cs.Id,TRUE); //Collect the IDs of the cases that are Submitted
                    }else if(cs.CPT_Form_Intake_Status__c=='In Progress' && cs.Status!='Cancelled'){
                        //if(oldMap.get(cs.id).status != cs.Status) //&& old_intake_status!=current_intake_status
                            CaseDraftMap.put(cs.Id,TRUE); //Collect the IDs of the cases that are NOT Submitted
                    }
                    system.debug('>>>>>86>herein>>');
                }
            }
            }
            
            
            
            if((TransactionTypeIds!=null && !TransactionTypeIds.isEmpty()) && ((CaseSubmittedMap!=null && !CaseSubmittedMap.isEmpty()) || (CaseDraftMap!=null && !CaseDraftMap.isEmpty()))) //check if the Transaction Type IDs list is null
            {                                
                //Collect the Certificate Associations
                List<ILPB__Certificate_Transaction_Association__c> CTAssoc = [SELECT ID,Name, ILPB__Transaction_Type_Name__c,ILPB__Transaction_Type_Name__r.Name, ILPB__Transaction_Template__c,  
                                                                              ILPB__Transaction_Template__r.ILPB__Current_Version__c ,ILPB__Certificate_Type__c
                                                                              FROM ILPB__Certificate_Transaction_Association__c 
                                                                              WHERE ILPB__Transaction_Type_Name__c IN:TransactionTypeIds];
                List<Id> VersionIds = new List<ID>();
                Map<ID,ILPB__Transaction_Type_Lifecycle_Step__c> VersionSubmittedStepMap = new Map<ID,ILPB__Transaction_Type_Lifecycle_Step__c>();
                Map<ID,ILPB__Transaction_Type_Lifecycle_Step__c> VersionNewStepMap = new Map<ID,ILPB__Transaction_Type_Lifecycle_Step__c>();
                system.debug('>>>>>100>herein>>>');
                for(ILPB__Certificate_Transaction_Association__c CTA: CTAssoc)
                {
                    TransTypeCTAMap.put(CTA.ILPB__Transaction_Type_Name__c,CTA); //Create a map of Transaction Type ID and the Certificate Association Record
                    VersionIds.add(CTA.ILPB__Transaction_Template__r.ILPB__Current_Version__c); //Collect the Trans Type Version IDs
                    system.debug('>>>>106>>herein>>'+CTA.ILPB__Transaction_Type_Name__c+'>>>>>>>>>>>>>'+CTA.ILPB__Transaction_Template__r.ILPB__Current_Version__c);
                }
                
                system.debug('>>>>106>>herein>>>'+TransTypeCTAMap);
                if(CaseSubmittedMap.size()>0)
                {
                    system.debug('>>>>110>>>'+CaseSubmittedMap);
                   
                        //Collect the List of the Submitted LifeCycle Steps
                    List<ILPB__Transaction_Type_Lifecycle_Step__c> LCStep = [SELECT Id,Name, ILPB__Transaction_Type_Template_Version__c, ILPB__Name__c, ILPB__Standard_Lifecycle_Step__c, ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Status_Value__c ,  ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Sub_Status_Value__c, (SELECT ID,NAME FROM ILPB__Lifecycle_Step_Associations__r) FROM ILPB__Transaction_Type_Lifecycle_Step__c WHERE ILPB__Transaction_Type_Template_Version__c IN :VersionIds AND ILPB__Submitted_Step__c=TRUE]; //AND ILPB__Submitted_Step = TRUE
                    system.debug('>>>>112>>herein>>>'+LCStep);
                    for(ILPB__Transaction_Type_Lifecycle_Step__c LC: LCStep)
                    {
                        VersionSubmittedStepMap.put(LC.ILPB__Transaction_Type_Template_Version__c, LC); //Create a Map of Version ID and the Submitted LifeCycle Step
                    } 
                    system.debug('>>>>117>>herein>>>'+VersionSubmittedStepMap);
                }
                
                if(CaseDraftMap.size()>0)
                {
                    system.debug('>>>>new>>herein>>>'+CaseDraftMap);
                    //Collect the List of the New (First) LifeCycle Steps
                    List<ILPB__Transaction_Type_Lifecycle_Step__c> LCSteps = [SELECT Id,Name, ILPB__Transaction_Type_Template_Version__c,ILPB__Standard_Lifecycle_Step__c, ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Status_Value__c ,  ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Sub_Status_Value__c,  (SELECT ID,NAME FROM ILPB__Lifecycle_Step_Associations1__r) FROM ILPB__Transaction_Type_Lifecycle_Step__c WHERE ILPB__Transaction_Type_Template_Version__c IN :VersionIds ]; 
                    
                     system.debug('>>>>126>>herein>>>'+LCSteps);
                    system.debug('>>>>126>>herein>>>'+LCSteps.size());
                    
                    for(ILPB__Transaction_Type_Lifecycle_Step__c LC : LCSteps)
                    {
                        system.debug('>>>>126>>herein>>>'+LC.ILPB__Lifecycle_Step_Associations__r.size());
                        if(LC.ILPB__Lifecycle_Step_Associations1__r.size()==0)
                        {
                            VersionNewStepMap.put(LC.ILPB__Transaction_Type_Template_Version__c, LC);//Create a Map of Version ID and the New(First) LifeCycle Step
                        }
                    }
                    
                                    system.debug('>>>>13 VersionNewStepMap6>>herein>>>'+VersionNewStepMap);                
                    
                }
                
                Group submittedQueue = [select Id from Group where DeveloperName = 'Submitted_Transaction_Pending_Screening' and Type = 'Queue'];
                
                
                Database.DMLOptions options = new Database.DMLOptions();
                options.assignmentRuleHeader.useDefaultRule = false;
                
                List<ILPB__Transaction_Certificate_Role__c> TCRChair = new List<ILPB__Transaction_Certificate_Role__c>();
                List<Case> casesToUpdate = new List<Case>();
                if((TransTypeCTAMap!=null && !TransTypeCTAMap.isEmpty()) &&((VersionSubmittedStepMap!=null && !VersionSubmittedStepMap.isEmpty()) || (VersionNewStepMap!=null && !VersionNewStepMap.isEmpty())))
                {
                    //Id AppRoleTCR = ILPB__Transaction_Certificate_Role__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('CPT_Applicant_Role').getRecordTypeId();
                    List<IFFB__Category__c> StdRoles = new List<IFFB__Category__c>();
                    
                    for(Case cs:newCases)
                    {
                        cs.ILPB__Transaction_Template__c = TransTypeCTAMap.get(cs.ILPB__Transaction_Type__c).ILPB__Transaction_Template__c;
                        cs.ILPB__Transaction_Type_Template_Version__c = Id.valueOf(TransTypeCTAMap.get(cs.ILPB__Transaction_Type__c).ILPB__Transaction_Template__r.ILPB__Current_Version__c);
                        cs.ILPB__Certificate_Type__c = TransTypeCTAMap.get(cs.ILPB__Transaction_Type__c).ILPB__Certificate_Type__c;
                        system.debug('>>>>142>>herein>>>');
                        if(CaseSubmittedMap.containskey(cs.Id))  //Check if the CaseSubmittedMap contains the current CaseId 
                        {
                            system.debug('>>>>>220>>>>>'+cs.CPT_Chairperson_Attribute__c);
                            
                             system.debug('>>>>145>>herein>>>'+VersionSubmittedStepMap);
                            cs.ILPB__Transaction_Lifecycle_Step__c = VersionSubmittedStepMap.get(cs.ILPB__Transaction_Type_Template_Version__c).Id;
                            cs.Status = VersionSubmittedStepMap.get(cs.ILPB__Transaction_Type_Template_Version__c).ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Status_Value__c;
                            cs.ILPB__Transaction_SubStatus__c = VersionSubmittedStepMap.get(cs.ILPB__Transaction_Type_Template_Version__c).ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Sub_Status_Value__c;
                            cs.ILPB__Date_Time_Submitted__c = datetime.now();
                            cs.CPT_Report_Year__c = string.valueof(datetime.now().year());
                            
                            
                             system.debug('>>>>>22222222222222222>>>>>'+submittedQueue.Id);
                            cs.OwnerId = submittedQueue.Id;
                            cs.ILPB__Submitter__c = cs.ILPB__Form_Intake__c == null && context == 'insert' ? cs.CreatedById : cs.ILPB__Form_Intake__r.CreatedById;
                            cs.Subject = TransTypeCTAMap.get(cs.ILPB__Transaction_Type__c).ILPB__Transaction_Type_Name__r.Name + ' for '+ cs.Account.Name + ' - '+cs.ILPB__Date_Time_Submitted__c.format('MM/dd/yyyy');
                            //cs.CPT_Decision_Summary__c =cs.CPT_Form_Intake_Status__c ;
                            if(cs.ILPB__Form_Intake__r.CreatedBy.ContactId!=null){
                                cs.ContactId = cs.ILPB__Form_Intake__r.CreatedBy.ContactId;
                            }
                            else if(cs.ILPB__Form_Intake__c == null && context == 'insert' && cs.CreatedBy.ContactId != null)
                            {
                                cs.ContactId = cs.CreatedBy.ContactId;
                            }

                            if(cs.Account.CPT_Certificate_related__c!=null){
                                cs.AssetId = cs.Account.CPT_Certificate_related__c;
                            }
                           
                            //
                        }
                        else{ // If the CaseSubmittedMap does NOT contain the current CaseId, get the New Lifecycle step Map
                            system.debug('>>155>>>>>>'+VersionNewStepMap);
                            cs.ILPB__Transaction_Lifecycle_Step__c = VersionNewStepMap.get(cs.ILPB__Transaction_Type_Template_Version__c).Id;
                            cs.Status = VersionNewStepMap.get(cs.ILPB__Transaction_Type_Template_Version__c).ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Status_Value__c;
                            cs.ILPB__Transaction_SubStatus__c = VersionNewStepMap.get(cs.ILPB__Transaction_Type_Template_Version__c).ILPB__Standard_Lifecycle_Step__r.ILPB__Corresponding_Sub_Status_Value__c;
                            cs.ILPB__Submitter__c = cs.ILPB__Form_Intake__r.CreatedById;
                        }
                        
                        system.debug('>>>>>244444449999999>>>>>'+cs.OwnerId);
                        cs.setOptions(options);
                        casesToUpdate.add(cs);
                    }
                }
                
                
                
                
                if(casesToUpdate.size()>0){
                   
                    
                    update casesToUpdate;
                    
                }
                
/*                if(TCRChair.size()>0){
                    insert TCRChair;
                }*/
            }
        }
    }

    public static void createChairPersonRole(Map<Id,Case> newMap, Map<Id,Case>oldMap)
    {
        List<String> caseIds = new List<String>();
        List<ILPB__Transaction_Certificate_Role__c> TCRChair = new List<ILPB__Transaction_Certificate_Role__c>();
        Id AppRoleTCR = ILPB__Transaction_Certificate_Role__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('CPT_Applicant_Role').getRecordTypeId();
        for(Case cs : newMap.values())
        {
            if(oldMap != null && oldMap.get(cs.Id).CPT_Chairperson_Attribute__c != cs.CPT_Chairperson_Attribute__c && cs.CPT_Chairperson_Attribute__c == 'I am the Chairperson')
            {
                caseIds.add(cs.Id);            
            }
            else if(oldMap == null && cs.CPT_Chairperson_Attribute__c == 'I am the Chairperson')
            {
                caseIds.add(cs.Id);
            }
        }
        
        if(!caseIds.isEmpty())
        {
            List<Case> cases = [SELECT Id, Account.CPT_Chair_Person__r.FirstName, Account.CPT_Chair_Person__r.LastName, Account.CPT_Chair_Person__r.Email, CPT_Chairperson_Attribute__c FROM Case WHERE Id IN:caseIds];        
            
            if(!cases.isEmpty())
            {
                for(Case cs : cases)
                {
                    ILPB__Transaction_Certificate_Role__c chair = new ILPB__Transaction_Certificate_Role__c();
                    chair.RecordTypeId = AppRoleTCR;
                    chair.CPT_First_Name__c  = cs.Account.CPT_Chair_Person__r.FirstName;
                    chair.CPT_Last_Name__c   = cs.Account.CPT_Chair_Person__r.LastName;
                    chair.CPT_Email__c  = cs.Account.CPT_Chair_Person__r.Email;
                    chair.CPT_Category__c  = 'Chairperson';
                    chair.ILPB__Transaction__c = cs.Id;
                    TCRChair.add(chair);
                    system.debug('>>>>>230>>>'+TCRChair);
                }            
            }        
        }

        if(!TCRChair.isEmpty())
        {
            insert TCRChair;
        }
    }
    
    

    
    
     /**
    * @description This Method will create new Transaction Event .
    * @param newMap Map of Id to new version of Case records
    * @param oldMap Map of Id to old version of Case records 
    */ 
    
    public static void createTransactionEvent(Map<Id,Case> oldMap, Map<Id,Case> newMap) 
    {
        List<ILPB__Transaction_Event__c> transactionEventList = new List<ILPB__Transaction_Event__c> ();
        Map<Id,ILPB__Transaction_Event__c> transactionEventMap = new Map<Id,ILPB__Transaction_Event__c> ();
        
        Set<ID> queueIDSet = new Set<Id> ();
        Set<ID> userIDSet = new Set<ID> ();
        
        Map<id,User> userMap = new Map<id,User> ();
        Map<id,Group> queueMap = new Map<id,Group> ();
        
        for(Case cs : newMap.values()) {
            if(String.valueOf(cs.ownerID).startsWith('005') && CPT_CaseRecordType.check(cs.RecordTypeId)) {
                userIDSet.add(cs.ownerID);
            } else {
                queueIDSet.add(cs.ownerID);
            }
        }
        
        if (userIDSet != null && userIDSet.size() > 0) {
            userMap = new Map<id,user> ([select id,name from user where ID IN:userIDSet]);
        }
        
        if (queueIDSet != null && queueIDSet.size() > 0) {
            queueMap = new Map<id,Group> ([select id,name from Group where ID IN:queueIDSet AND Type = 'Queue']);
        }
        
        if(oldMap != null) {
            transactionEventList = [select id,ILPB__State_Out_Date_Time__c,ILPB__State_Out_Modified_By__c,ILPB__Transaction__c from ILPB__Transaction_Event__c where ILPB__State_Out_Date_Time__c = null AND ILPB__Transaction__c=:newMap.keyset()];
            for(ILPB__Transaction_Event__c transactionEvent : transactionEventList) {
                transactionEventMap.put(transactionEvent.ILPB__Transaction__c,transactionEvent);
            }
        }
        
        List<ILPB__Transaction_Event__c> transactionEventListToUpsert = new List<ILPB__Transaction_Event__c> ();
        
        for(Case cs : newMap.values()) {
            ILPB__Transaction_Event__c transactionEventListToInsert = new ILPB__Transaction_Event__c();
            ILPB__Transaction_Event__c transactionEventListToUpdate = new ILPB__Transaction_Event__c();
            if(cs.ILPB__Transaction_Lifecycle_Step__c != null) {
                Boolean insertActivity = false;
                if(oldMap == null) {
                    insertActivity = true;
                } else {
                    if(oldMap.get(cs.id).status != cs.Status || oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != cs.ILPB__Transaction_SubStatus__c || oldMap.get(cs.id).ILPB__Transaction_Lifecycle_Step__c != cs.ILPB__Transaction_Lifecycle_Step__c || oldMap.get(cs.id).ownerID != cs.ownerID) {
                        insertActivity = true;
                   }
                }
                if(insertActivity) {
                    transactionEventListToInsert.ILPB__Status__c = cs.status;
                    transactionEventListToInsert.ILPB__Transaction_Sub_Status__c = cs.ILPB__Transaction_SubStatus__c;
                    transactionEventListToInsert.ILPB__Transaction_Type_Lifecycle_Step__c = cs.ILPB__Transaction_Lifecycle_Step__c;
                    if(String.valueOf(cs.ownerID).startsWith('005') && userMap.size()>0) {
                        system.debug('######->'+cs.ownerID);
                        system.debug('userMap>>>>>'+userMap);
                        transactionEventListToInsert.CPT_Transaction_Owner__c= userMap.get(cs.ownerID).Name;
                    } else if(userMap.size()>0){
                        transactionEventListToInsert.CPT_Transaction_Owner__c= queueMap.get(cs.ownerID).Name;
                    }
                    transactionEventListToInsert.ILPB__State_In_Date_Time__c = system.now();
                    transactionEventListToInsert.ILPB__State_In_Modified_By__c = UserInfo.getUserId();
                    transactionEventListToInsert.ILPB__Transaction__c = cs.id;
                    transactionEventListToUpsert.add(transactionEventListToInsert);
                    if(oldMap != null && transactionEventMap.get(cs.id) != null) {
                        transactionEventListToUpdate = transactionEventMap.get(cs.id);
                        transactionEventListToUpdate.ILPB__State_Out_Date_Time__c = system.now();
                        transactionEventListToUpdate.ILPB__State_Out_Modified_By__c = UserInfo.getUserId();
                        transactionEventListToUpsert.add(transactionEventListToUpdate);
                    }
 
                }
                    
            }    
        } 
        
        if(transactionEventListToUpsert != null && transactionEventListToUpsert.size() > 0) {
            upsert transactionEventListToUpsert;
        }
    }
    
    /**
    * @description This Method will update Life cycle step on case.
    * @param newMap Map of Id to new version of Case records
    * @param oldMap Map of Id to old version of Case records 
    */ 
    public static void updateLifeCycleStep(Map<Id,Case> oldMap, Map<Id,Case> newMap)
    {
        for(Case cs:newMap.Values())
        {
            
            system.debug('old stat>>>>>>>'+oldMap.get(cs.id).status );
            system.debug('old substat>>>>'+oldMap.get(cs.id).ILPB__Transaction_SubStatus__c);
            system.debug('new stat>>>>>>>'+cs.Status );
            system.debug('new substat>>>>'+cs.ILPB__Transaction_SubStatus__c);
            system.debug('RT check>>>>>>>'+CPT_CaseRecordType.check(cs.RecordTypeId));
            
           //if((checkRecursive.runOnce() && oldMap.get(cs.id).status != null && oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != null) && (oldMap.get(cs.id).status != cs.Status || oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != cs.ILPB__Transaction_SubStatus__c) && CPT_CaseRecordType.check(cs.RecordTypeId)) 
           if((oldMap.get(cs.id).status != null && oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != null) && (oldMap.get(cs.id).status != cs.Status || oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != cs.ILPB__Transaction_SubStatus__c) && CPT_CaseRecordType.check(cs.RecordTypeId)) 
            {
                //system.debug('checkRecursive>>>>>'+checkRecursive.runOnce());
                if(checkRecursive.runOnce())
                {
                //CPT_UpdateTransLifeCycleStep.updateStep(cs.Id);
                List<ILPB.BaseLC_InvocableUpdateTransLifeCycleStep.TransactionVariables> transVars = new List<ILPB.BaseLC_InvocableUpdateTransLifeCycleStep.TransactionVariables>();
                ILPB.BaseLC_InvocableUpdateTransLifeCycleStep.TransactionVariables transVar = new ILPB.BaseLC_InvocableUpdateTransLifeCycleStep.TransactionVariables();
                transVar.caseId = cs.Id;
                transVar.transLCStepId = cs.ILPB__Transaction_Lifecycle_Step__c;
                transVars.add(transVar);
                ILPB.BaseLC_InvocableUpdateTransLifeCycleStep.updateLifeCycleStep(transVars);
                }
            }
        }
    }
     
    /**
    * @description This Method will update previous Case status and Substatus on case.
    * @param newMap Map of Id to new version of Case records
    * @param oldMap Map of Id to old version of Case records 
    */
    
    public static void updatePrevStatusSubstatus(Map<Id,Case> oldMap, Map<Id,Case> newMap){
        for(Case cs:newMap.values())
        {
            if(CPT_CaseRecordType.check(cs.RecordTypeId) && (oldMap.get(cs.id).status != null && oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != null) && (oldMap.get(cs.id).status != cs.Status || oldMap.get(cs.id).ILPB__Transaction_SubStatus__c != cs.ILPB__Transaction_SubStatus__c)) 
            {
                cs.CPT_Previous_Case_Status__c = oldMap.get(cs.id).status;
                cs.CPT_Previous_Case_SubStatus__c = oldMap.get(cs.id).ILPB__Transaction_SubStatus__c;
            }
                     
        }
    }
    
    
   /* public static void createUser (Map<Id,Case> oldMap, Map<Id,Case> newMap){
        CPT_NewInstitutionUserCreation.createUser(oldMap,newMap);
    }*/
    
    /**
    * @description This Method will update ContactId on Case for New Institution users.
    * @param newMap Map of Id to new version of Case records
    * @param oldMap Map of Id to old version of Case records 
    */ 
    
    public static void updateNewUserContact(Map<Id,Case> oldMap, Map<Id,Case> newMap)
    {
        Set<Id> caseIds = new Set<Id>();
        List<User> Users = new List<User>();
        List<Contact> contacts = new List<Contact>();
        Set<String> UserIds = new Set<String>();
        
        for(Case cs:oldMap.values())
        {
            if(CPT_CaseRecordType.check(cs.RecordTypeId) && (oldMap.get(cs.id).status =='New'))
            {
                caseIds.add(cs.Id);
                UserIds.add(cs.CreatedById);            
            }
        }
        
        if(!UserIds.isEmpty())
        {
           Users = [Select Id,FirstName,LastName,ContactId From User where Id IN:UserIds];
        }

        if(!Users.isEmpty())
        {
            contacts=[Select Id,CPT_Institution_User_Status__c,CPT_Role__c,Phone From Contact where Id =:Users[0].ContactId];
        }
        List<Case> newCases = new List<Case>();

        if(!contacts.isEmpty())
        {
            for(Case caseslist: oldMap.values())
            {
                Case cs = new Case(ContactId = contacts[0].Id, Id = caseslist.Id);
                newCases.add(cs);
            }
        }

        if(!newCases.isEmpty())
        {
            update newCases;
        }
    }
}