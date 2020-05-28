
/** [[https://developer.chrome.com/extensions/nativeMessaging#native-messaging-host-protocol|Native messaging protocol]]*/
namespace Connection {

delegate void OnDataReceived(Json.Object json);

void create(OnDataReceived handler) {
    if (created)
        return;
    generator = new Json.Generator();
    parser = new Json.Parser();
    data_received = handler;
    try {
        var channel = new IOChannel.unix_new(stdin.fileno());
        channel.set_encoding(null);
        channel.set_buffered(false);
        channel.add_watch(IOCondition.IN, read_data);
    } catch (IOChannelError e) {
        error("stdin unavailable: %s.", e.message);
    }
    created = true;
}

void send_data(Json.Object data) {
    var root = new Json.Node(Json.NodeType.OBJECT);
    root.set_object(data);
    generator.set_root(root);
    size_t length;
    string str_data = generator.to_data(out length);
    uint32 len32 = (uint32)length;
    stdout.write((uint8[])&len32);
    stdout.write(str_data.data);
    stdout.flush();
    debug("send_data: %s", (string)str_data.data);
}

bool read_data(IOChannel source, IOCondition condition) {
    if (condition == IOCondition.HUP) {
        error("Connection lost.\n");
    }
    try {
        size_t rc;
        uint32 length = 0;
        source.read_chars((char[])&length, out rc);
        char[] data = new char[length];
        source.read_chars(data, out rc);
        debug("read_data: %s", (string)data);
        parser.load_from_data((string)data, length);
    }
    // Actually only IOChannelError (no ConvertError when no encoding).
    catch (Error e) {
        warning("%s %s\n", e.domain.to_string(), e.message);
        return false;
    }
    var json = parser.get_root().get_object();
    // FIXME: sent event
    data_received(json);
    return true;
}

Json.Generator generator;
Json.Parser    parser;
unowned OnDataReceived data_received;
bool created = false;

}

