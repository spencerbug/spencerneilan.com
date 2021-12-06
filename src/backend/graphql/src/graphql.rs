use sudograph::graphql_database;

graphql_database!("src/backend/graphql/src/schema.graphql");


// #[update]
// async fn graphql_secure_mutation(mutation_string: String, variables_json_string: String) -> String {

//     let ec2_principal = ic_cdk::export::Principal::from_text("y6lgw-chi3g-2ok7i-75s5h-k34kj-ybcke-oq4nb-u4i7z-vclk4-hcpxa-hqe").expect("should be able to decode");
    
//     if ic_cdk::caller() != ec2_principal {
//         panic!("Not authorized");
//     }

//     return graphql_mutation(mutation_string, variables_json_string).await;
// }

