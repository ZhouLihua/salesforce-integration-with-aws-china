trigger awsEventBridgeTrigger on Account (after insert, after update, after delete) {
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
        EventSender.SendMessage(JSON.serialize(event));
    }
}
