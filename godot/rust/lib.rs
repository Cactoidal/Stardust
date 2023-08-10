use gdnative::{prelude::*, core_types::ToVariant};
use ethers::{core::{abi::{struct_def::StructFieldType, AbiEncode}, types::*}, utils::*, signers::*, providers::*, prelude::SignerMiddleware};
use ethers_contract::{abigen, core::k256::sha2::Sha256};
use std::{convert::TryFrom, sync::Arc};
use tokio::runtime::{Builder, Runtime};
use futures::Future;
use tokio::macros::support::{Pin, Poll};
use serde_json::json;
use openssl::{sha::sha256};

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

    handle.add_class::<AsyncExecutorDriver>();
    handle.add_class::<CCIP>();
}

struct myVec(Vec<ethers::types::U256>);

abigen!(
    Stardust,
    "./Stardust.json",
    event_derives(serde::Deserialize, serde::Serialize)
);


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

#[derive(NativeClass, Debug, ToVariant, FromVariant)]
#[inherit(Node)]
struct CCIP;

#[methods]
impl CCIP {
    fn new(_owner: &Node) -> Self {
        CCIP
    }

#[method]
fn get_address(key: PoolArray<u8>) -> GodotString {

let vec = &key.to_vec();

let keyset = &vec[..]; 
 
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();

let wallet: LocalWallet = prewallet.with_chain_id(Chain::AvalancheFuji);

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
async fn get_balance(user_address: GodotString, rpc: GodotString, ui_node: Ref<Control>) -> NewFuture {

let preaddress: &str = &user_address.to_string();

let address: Address = preaddress.parse().unwrap();

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

let balance = &provider.get_balance(address, None).await.unwrap().as_u128().to_string().to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_balance", &[balance.clone()])
};

NewFuture(Ok(()))
}


#[method]
#[tokio::main]
async fn create_pilot(key: PoolArray<u8>, chain_id: u64, stardust_contract: GodotString, rpc: GodotString, name: GodotString) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();

let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = stardust_contract.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = Stardust::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.create_pilot(name.to_string()).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}


#[method]
#[tokio::main]
async fn ccip_send(key: PoolArray<u8>, chain_id: u64, stardust_address: GodotString, rpc: GodotString, chain_selector: GodotString, destination_address: GodotString, cargo: GodotString) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..];
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = stardust_address.to_string().parse().unwrap();

let destination: Address = destination_address.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = Stardust::new(contract_address.clone(), Arc::new(client.clone()));

let preselect: &str = &chain_selector.to_string();

let selector: u64 = u64::from_str_radix(preselect, 16).unwrap();

let encode_string: &str = &cargo.to_string();

let encoded = ethers::abi::AbiEncode::encode(encode_string);

let mut sha =  openssl::sha::Sha256::new();

sha.update(&encoded);

let hashed = sha.finish();

let bytes: ethers::types::Bytes = hashed.into();

let tx = contract.ccip_send(u64::from(selector), destination, 1, bytes).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}



#[method]
#[tokio::main]
async fn declare_cargo(key: PoolArray<u8>, chain_id: u64, stardust_address: GodotString, rpc: GodotString, salt: GodotString, amount1: GodotString, amount2: GodotString, amount3: GodotString) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..];
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = stardust_address.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = Stardust::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.declare_cargo(salt.to_string(), amount1.to_string(), amount2.to_string(), amount3.to_string()).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}




#[method]
#[tokio::main]
async fn pilot_info(key: PoolArray<u8>, chain_id: u64, stardust_address: GodotString, rpc: GodotString, pilot_address: GodotString, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 

let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = stardust_address.to_string().parse().unwrap();

let pilot: Address = pilot_address.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = Stardust::new(contract_address.clone(), Arc::new(client.clone()));

let prequery = contract.pilot_info(pilot).call().await.unwrap();

let query = json!({
    "name": prequery.name,
    "level": prequery.level,
    "holdSize": prequery.hold_size,
    "cargo": prequery.cargo,
    "coinBalance": prequery.coin_balance,
    "job": prequery.job,
    "antimatterModule": prequery.antimatter_module,
    "recycler": prequery.recycler,
    "dustCatcher": prequery.dust_catcher,
    "onChain": prequery.on_chain
});

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_pilot", &[query.to_string().to_variant()])
};

NewFuture(Ok(()))

}


#[method]
#[tokio::main]
async fn get_departure(key: PoolArray<u8>, chain_id: u64, stardust_address: GodotString, rpc: GodotString, pilot_address: GodotString, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 

let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = stardust_address.to_string().parse().unwrap();

let pilot: Address = pilot_address.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = Stardust::new(contract_address.clone(), Arc::new(client.clone()));

let prequery = contract.last_departed(pilot).call().await.unwrap();

let query: Variant = format!{"{:?}", prequery}.to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_departure_time", &[query])
};


NewFuture(Ok(()))

}



#[method]
#[tokio::main]
async fn get_departure_epoch(key: PoolArray<u8>, chain_id: u64, stardust_address: GodotString, rpc: GodotString, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 

let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = stardust_address.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = Stardust::new(contract_address.clone(), Arc::new(client.clone()));

let epoch1 = contract.get_outgoing_pilots().call().await.unwrap();

let query: Variant = format!{"{:?}", epoch1}.to_variant();

let epoch2 = contract.get_outgoing_pilots_2().call().await.unwrap();

let query2: Variant = format!{"{:?}", epoch2}.to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_incoming_ships", &[query, query2])
};

NewFuture(Ok(()))

}






#[method]
fn get_abi_encode(encode: GodotString) -> Variant {

    let encode_string: &str = &encode.to_string();

    let encoded = ethers::abi::AbiEncode::encode(encode_string);

    let mut sha =  openssl::sha::Sha256::new();

    sha.update(&encoded);

    let hashed = sha.finish();

    //try feeding this straight to transaction
    //let bytes: ethers::types::Bytes = hashed.into();

    let hash_string = format!("{:?}", hex::encode(hashed)).to_variant();

    return hash_string;
}



}

godot_init!(init);
