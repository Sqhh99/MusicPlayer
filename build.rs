fn main() {
    println!("cargo:rerun-if-changed=resources/appIcon.ico");

    // Embeds the executable icon. Resource ID 1 is also what GPUI loads for its windows.
    #[cfg(windows)]
    {
        let mut resource = winresource::WindowsResource::new();
        resource.set_icon("resources/appIcon.ico");
        resource.set("ProductName", "MusicPlayer");
        resource.set("FileDescription", "MusicPlayer");
        if let Err(err) = resource.compile() {
            panic!("failed to embed Windows resources: {err}");
        }
    }
}
