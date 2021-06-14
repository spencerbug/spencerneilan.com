import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

shared({ caller = initializer }) actor class() {

    public type Account = {
        firstName: Text;
        lastName: Text;
        company: Text;
        companyPosition: Text;
        email: Text;
        imgUrl: Text;
    };

    var accountsTable: HashMap.HashMap<Principal, Account> = HashMap.HashMap<Principal, Account>(1, Principal.equal, Principal.hash);

    public query func getAccount(id: Principal): async ?Account {
        accountsTable.get(id)
    };

    public shared query(msg) func getMyAccount(): async ?Account {
        accountsTable.get(msg.caller)
    };

    public shared(msg) func upsertAccount( id: Principal, account: Account ): async () {
        if ( msg.caller != initializer ) {
            throw Error.reject ("You must be the Owner");
        };
        accountsTable.put(id, account);
    };

    public shared(msg) func upsertMyAccount ( account: Account ): async () {
        accountsTable.put(msg.caller, account);
    };

    public shared query(msg) func whoAmI() : async Principal {
        msg.caller
    };

}