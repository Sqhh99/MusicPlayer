fn main() {
    println!("cargo:rerun-if-changed=resources/appIcon.ico");

    // Embeds the executable icon. Resource ID 1 is also what GPUI loads for its windows.
    #[cfg(windows)]
    {
        let mut resource = winresource::WindowsResource::new();
        resource.set_icon("resources/appIcon.ico");
        resource.set("ProductName", "Mi");
        resource.set("FileDescription", "Mi - local music player");
        resource.set("OriginalFilename", "Mi.exe");
        resource.set("InternalName", "Mi");
        resource.set("ProductVersion", env!("CARGO_PKG_VERSION"));
        resource.set("FileVersion", env!("CARGO_PKG_VERSION"));
        if let Err(err) = resource.compile() {
            panic!("failed to embed Windows resources: {err}");
        }
    }
}
