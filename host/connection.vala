
/** [[https://developer.chrome.com/extensions/nativeMessaging#native-messaging-host-protocol|Native messaging protocol]]*/
namespace Connection {

delegate void OnDataReceived(Json.Object json);

void create(OnDataReceived handler) {
    if (created)
        return;
    generator = new Json.Generator();
    parser = new Json.Parser();
    data_received = handler;

    var channel = new IOChannel.unix_new(stdin.fileno());
    channel.set_encoding(null);
    channel.set_buffered(false);
    channel.add_watch(IOCondition.IN, read_data);

    created = true;
}

void send_data(Json.Object data) {
    debug("send_data()");
    var root = new Json.Node(Json.NodeType.OBJECT);
    root.set_object(data);
    generator.set_root(root);
    size_t length;
    string str_data = generator.to_data(out length);
    uint32 len32 = (uint32)length;
    stdout.write((uint8[])&len32);
    stdout.write(str_data.data);
    stdout.flush();
    debug((string)data);
}

bool read_data(IOChannel source, IOCondition condition) {
    debug("read_data()");
    size_t rc;
    uint32 length = 0;
    source.read_chars((char[])&length, out rc);
    char[] data = new char[length];
    source.read_chars(data, out rc);
    debug((string)data);
    parser.load_from_data((string)data, length);
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

