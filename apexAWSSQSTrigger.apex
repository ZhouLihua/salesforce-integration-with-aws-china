trigger awsSQSTrigger on Account (after insert, after update, after delete) {
   System.debug('After insert');
    for(Account acc: Trigger.new){
           string action = 'default';
           if (Trigger.isInsert){
            action = 'insert';
            }
          if (Trigger.isUpdate){
            action = 'update';
           }
         if (Trigger.isDelete){
            action = 'delete';
           }
           AccountEvent event = new AccountEvent(action, acc);
            SqsSender.SendMessage(JSON.serialize(event));
    }
}