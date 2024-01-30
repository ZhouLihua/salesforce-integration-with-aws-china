public class AccountEvent {
    private string action;
    private Account details;
    public AccountEvent(string action, Account details){
        this.action = action;
        this.details = details;
    }
}