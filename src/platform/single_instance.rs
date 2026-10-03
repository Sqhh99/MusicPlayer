//! Keeps a single running instance: later launches ask the first one to show its window.

use std::io::{Read, Write};

use interprocess::local_socket::prelude::*;
use interprocess::local_socket::{GenericNamespaced, ListenerOptions, Name};

const SOCKET_NAME: &str = "com.sqhh99.Mi.instance";
const ACTIVATE: &[u8] = b"ACTIVATE";

pub enum Instance {
    /// This is the first instance. Holds the listener when one could be created.
    Primary(Option<LocalSocketListener>),
    /// Another instance is running and has been asked to activate.
    Secondary,
}

fn socket_name() -> std::io::Result<Name<'static>> {
    SOCKET_NAME.to_ns_name::<GenericNamespaced>()
}

pub fn acquire() -> Instance {
    let Ok(name) = socket_name() else {
        return Instance::Primary(None);
    };
    if let Ok(mut stream) = LocalSocketStream::connect(name.clone()) {
        if let Err(err) = stream.write_all(ACTIVATE) {
            log::warn!("cannot signal running instance: {err}");
        }
        return Instance::Secondary;
    }
    match ListenerOptions::new().name(name).create_sync() {
        Ok(listener) => Instance::Primary(Some(listener)),
        Err(err) => {
            log::warn!("single-instance listener unavailable: {err}");
            Instance::Primary(None)
        }
    }
}

/// Calls `on_activate` (on a background thread) whenever another launch asks for the window.
pub fn listen(listener: LocalSocketListener, on_activate: impl Fn() + Send + 'static) {
    std::thread::Builder::new()
        .name("single-instance".into())
        .spawn(move || {
            for connection in listener.incoming() {
                let Ok(mut connection) = connection else { continue };
                let mut message = Vec::new();
                if connection.read_to_end(&mut message).is_ok() && message == ACTIVATE {
                    on_activate();
                }
            }
        })
        .expect("failed to spawn single-instance thread");
}
