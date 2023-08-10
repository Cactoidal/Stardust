extern crate biscuit_auth as biscuit;


use gdnative::{prelude::*, core_types::ToVariant};
use biscuit_auth::{KeyPair, Biscuit};
use ethers::{core::{abi::{struct_def::StructFieldType, AbiEncode}, types::*}, utils::*, signers::*, providers::*, prelude::SignerMiddleware};
use ethers_contract::{abigen};
use std::{convert::TryFrom, sync::Arc};
use tokio::runtime::{Builder, Runtime};
use futures::Future;
use tokio::macros::support::{Pin, Poll};
use serde_json::json;

thread_local! {
    static EXECUTOR: &'static SharedLocalPool = {
        Box::leak(Box::new(SharedLocalPool::default()))
    };
}

#[derive(Default)]
struct SharedLocalPool {
    local_set: LocalSet,
}

impl futures::task::LocalSpawn for SharedLocalPool {
    fn spawn_local_obj(
        &self,
        future: futures::task::LocalFutureObj<'static, ()>,
    ) -> Result<(), futures::task::SpawnError> {
        self.local_set.spawn_local(future);

        Ok(())
    }
}

use tokio::task::LocalSet;

fn init(handle: InitHandle) {
    gdnative::tasks::register_runtime(&handle);
    gdnative::tasks::set_executor(EXECUTOR.with(|e| *e));

    handle.add_class::<BiscuitGenerator>();
    handle.add_class::<AsyncExecutorDriver>();
    handle.add_class::<KeyGen>();
}

struct myVec(Vec<ethers::types::U256>);


impl FromIterator<u8> for myVec {
    fn from_iter<T>(_: T) -> Self where T: IntoIterator, std::iter::IntoIterator::Item = A { todo!() }
}


#[derive(NativeClass, Debug, ToVariant, FromVariant)]
#[inherit(Node)]
struct BiscuitGenerator;

#[methods]
impl BiscuitGenerator {
    fn new(_owner: &Node) -> Self {
        BiscuitGenerator
    }
    
    #[method]
    fn generate_biscuits(mut blank: PoolArray<GodotString>, sxtfact1: GodotString, sxtfact2: GodotString, sxtfact3: GodotString, sxtfact4: GodotString) -> PoolArray<GodotString> {
        let root = KeyPair::new();
        let public: GodotString = root.public().to_bytes_hex().to_string().into();
        blank.push(public);
        let private: GodotString = hex::encode(root.private().to_bytes()).to_string().into();
        blank.push(private);

        let fact1: &str = &sxtfact1.to_string();
        let fact2: &str = &sxtfact2.to_string();
        let fact3: &str = &sxtfact3.to_string();
        let fact4: &str = &sxtfact4.to_string();

        let mut creator_biscuit = Biscuit::builder();
        creator_biscuit.add_fact(fact1).unwrap();
        creator_biscuit.add_fact(fact2).unwrap();
        blank.push(String::from_utf8(creator_biscuit.build(&root).unwrap().to_base64().unwrap().into_bytes()).unwrap().into());

        let mut reader_biscuit = Biscuit::builder();
        reader_biscuit.add_fact(fact3).unwrap();
        reader_biscuit.add_fact(fact4).unwrap();
        blank.push(String::from_utf8(reader_biscuit.build(&root).unwrap().to_base64().unwrap().into_bytes()).unwrap().into());

        blank
      
    }
}





#[derive(NativeClass)]
#[inherit(Node)]
struct AsyncExecutorDriver {
    runtime: Runtime,
}

impl AsyncExecutorDriver {
    fn new(_base: &Node) -> Self {
        AsyncExecutorDriver {
            runtime: Builder::new_current_thread()
                .enable_io() 	// optional, depending on your needs
                .enable_time() 	// optional, depending on your needs
                .build()
                .unwrap(),
        }
    }
}



#[methods]
impl AsyncExecutorDriver {
    #[method]
    fn _do_vrf2(&self, #[base] _base: &Node, key: PoolArray<u8>) {
        EXECUTOR.with(|e| {
            self.runtime
                .block_on(async {
                    e.local_set
                        .run_until(async {
                            tokio::task::spawn_local(async move {
                                
                                let vec = &key.to_vec();

                                let keyset = &vec[..]; 
                                     
                                let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
                                    
                                let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);
                                
                                let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");
                                
                                //contract
                                let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();
                                
                                let client = SignerMiddleware::new(provider, wallet);
                                
                                let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));
                                
                                let tx = contract.generate_query().send().await.unwrap().await.unwrap();
                                
                                }).await
                        })
                        .await
                })
                .unwrap()
        })
    }



    #[method]
    fn get_query2(&self, #[base] _base: &Node, key: PoolArray<u8>, creature_id: i32, ui_node: Ref<Control>) {
        EXECUTOR.with(|e| {
            self.runtime
                .block_on(async {
                    e.local_set
                        .run_until(async {
                            tokio::task::spawn_local(async move { 

                                godot_print!("it's happening");
                                
                                let vec = &key.to_vec();

                                let keyset = &vec[..]; 
                                     
                                let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
                                    
                                let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);
                                
                                let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");
                                
                                //contract
                                let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();
                                
                                let client = SignerMiddleware::new(provider, wallet);
                                
                                let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));
                                
                                let query = contract.get_query(U256::from(creature_id)).call().await.unwrap().to_string().to_variant();
                                
                                let node: TRef<Control> = unsafe { ui_node.assume_safe() };
                                
                                unsafe {
                                    node.call("set_query", &[query.clone()])
                                };
                                
                                
                                }).await
                        })
                        .await
                })
                .unwrap()
        })
    }


    #[method]
    fn do_something(&mut self, #[base] _base: &Node) {
        EXECUTOR.with(|e| {
            self.runtime
                .block_on(async {
                    e.local_set
                        .run_until(async {
                            tokio::task::spawn_local(async { 

                                godot_print!("it's happening");
                                
                                }).await
                        })
                        .await
                })
                .unwrap()
        })
    }

}


struct NewFuture(Result<(), Box<dyn std::error::Error + 'static>>);

impl ToVariant for NewFuture {
    fn to_variant(&self) -> Variant {todo!()}
}

struct NewStructFieldType(StructFieldType);



impl OwnedToVariant for NewStructFieldType {
    fn owned_to_variant(self) -> Variant {
        todo!()
    }
}

impl Future for NewFuture {
    type Output = NewStructFieldType;
    fn poll(self: Pin<&mut Self>, _: &mut std::task::Context<'_>) -> Poll<<Self as futures::Future>::Output> { todo!() }
}


abigen!(
    ChainlinkVRF,
    "./src/VRF.json",
    event_derives(serde::Deserialize, serde::Serialize)
);

abigen!(
    SxTRelay,
    "./src/Relay_ABI.json",
    event_derives(serde::Deserialize, serde::Serialize)
);



#[derive(NativeClass, Debug, ToVariant, FromVariant)]
#[inherit(Node)]
struct KeyGen;

#[methods]
impl KeyGen {
    fn new(_owner: &Node) -> Self {
        KeyGen
    }



#[method]
fn get_address(key: PoolArray<u8>) -> GodotString {

let vec = &key.to_vec();

let keyset = &vec[..]; 
 
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();

let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let address = wallet.address();

let address_string = address.encode_hex();

let key_slice = match address_string.char_indices().nth(*&0 as usize) {
    Some((_pos, _)) => (&address_string[26..]).to_string(),
    None => "".to_string(),
    };

let return_string: GodotString = format!("0x{}", key_slice).into();

return_string

}




#[method]
#[tokio::main]
async fn get_balance(user_address: GodotString, ui_node: Ref<Control>) -> NewFuture {

let preaddress: &str = &user_address.to_string();

let address: Address = preaddress.parse().unwrap();

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

let balance = &provider.get_balance(address, None).await.unwrap().as_u128().to_string().to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_balance", &[balance.clone()])
};

NewFuture(Ok(()))
}




#[method]
#[tokio::main]
async fn do_vrf(key: PoolArray<u8>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.generate_query().send().await.unwrap().await.unwrap();


NewFuture(Ok(()))
}



#[method]
#[tokio::main]
async fn get_creature(key: PoolArray<u8>, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let creature = contract.get_creature_id().call().await.unwrap().as_u32().to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_creature_id", &[creature.clone()])
};

NewFuture(Ok(()))

}




#[method]
#[tokio::main]
async fn check_query_return(key: PoolArray<u8>, creature_id: i32, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let response = contract.check_return(U256::from(creature_id)).call().await.unwrap().to_string().to_variant();

godot_print!("base response: {}", contract.check_return(U256::from(creature_id)).call().await.unwrap());
godot_print!("response: {}", response);

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("query_checked", &[contract.check_return(U256::from(creature_id)).call().await.unwrap().to_variant()])
};

NewFuture(Ok(()))

}



#[method]
#[tokio::main]
async fn get_query(key: PoolArray<u8>, creature_id: i32, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let query = contract.get_query(U256::from(creature_id)).call().await.unwrap().to_string().to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_query", &[query.clone()])
};

NewFuture(Ok(()))

}



#[method]
#[tokio::main]
async fn initialize_creature(key: PoolArray<u8>, creatureId: i32, hash: GodotString, location: i32, demeanor: i32) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.initialize_creature(U256::from(creatureId), hash.to_string(), U256::from(location), U256::from(demeanor)).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}






#[method]
#[tokio::main]
async fn check_hash(key: PoolArray<u8>, hash: GodotString, creatureId: f64, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let query = contract.check_hash(hash.to_string(), U256::from(creatureId as i64)).call().await.unwrap();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("hash_checked", &[query.to_variant()])
};

NewFuture(Ok(()))

}





#[method]
#[tokio::main]
async fn get_creatures(key: PoolArray<u8>, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let address: Address = wallet.address();

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let prequery = contract.get_creatures(address).call().await.unwrap();

let query: Variant = format!{"{:?}", prequery}.to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("got_player_creatures", &[query])
};

NewFuture(Ok(()))

}




#[method]
#[tokio::main]
async fn get_creature_object(key: PoolArray<u8>, creatureId: f64, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let prequery = contract.get_creature_object(U256::from(creatureId as i64)).call().await.unwrap();

let query = json!({
                    "hp": prequery.hp,
                    "attack": prequery.attack,
                    "abilities": prequery.abilities,
                    "location": prequery.location,
                    "demeanor": prequery.demeanor,
                    "initialized": prequery.instantiated
                });


//let query: Variant = format!{"{:?}", prequery}.to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("got_creature_object", &[query.to_string().to_variant()])
};

NewFuture(Ok(()))

}






#[method]
#[tokio::main]
async fn get_creature_objects(key: PoolArray<u8>, creatureIds: PoolArray<u8>, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));
//U256::from(creatureId as i64)

let mut id_vec = &creatureIds.to_vec();

//let v: Vec<U256> = id_vec.iter().map(U256).collect();

//let v = id_vec.iter().map(|&x| x).collect::<Vec<U256>>();

id_vec.into_iter().map(U256).collect();

let prequery = contract.get_creature_objects(creatureIds).call().await.unwrap();

let query = json!({
                    "hp": prequery.hp,
                    "attack": prequery.attack,
                    "abilities": prequery.abilities,
                    "location": prequery.location,
                    "demeanor": prequery.demeanor,
                    "initialized": prequery.instantiated
                });


//let query: Variant = format!{"{:?}", prequery}.to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("got_creature_object", &[query.to_string().to_variant()])
};

NewFuture(Ok(()))

}






#[method]
#[tokio::main]
async fn change_location(key: PoolArray<u8>, creatureId: f64, location: i64) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.change_location(U256::from(creatureId as i64), U256::from(location)).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}


#[method]
#[tokio::main]
async fn change_demeanor(key: PoolArray<u8>, creatureId: f64, demeanor: i64) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.change_demeanor(U256::from(creatureId as i64), U256::from(demeanor)).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}




#[method]
#[tokio::main]
async fn check_operational(key: PoolArray<u8>, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0xA1BecEaFeCd49F78804F20724B0e5c648f108faD".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = SxTRelay::new(contract_address.clone(), Arc::new(client.clone()));

let query = contract.check_operational().call().await.unwrap();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("checked_relay_status", &[query.to_variant()])
};

NewFuture(Ok(()))

}



#[method]
#[tokio::main]
async fn request_token(key: PoolArray<u8>, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0xA1BecEaFeCd49F78804F20724B0e5c648f108faD".parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = SxTRelay::new(contract_address.clone(), Arc::new(client.clone()));

let query = contract.get_token().call().await.unwrap();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("got_token", &[query.to_variant()])
};

NewFuture(Ok(()))

}








}

godot_init!(init);
