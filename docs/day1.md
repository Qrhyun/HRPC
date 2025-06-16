#  1.ProtoBuf协议数据结构定义
RPC通信交互的数据在`发送前`需要用ProtoBuf进行`二进制序列化`，并且在通信双方`收到后`要`对二进制序列化数据进行反序列化`。双方通信时
发送的都是固定结构的消息体，比如登录请求消息体(用户+密码)，注册请求消息体(用户ID+用户名+消息体)。
## 具体任务
- 完成`user.proto`的编写
- 生成头文件和主文件`protoc --cpp_out=. user.proto`
> 通过这个命令就能生成`user.cc`和`user.h`文件。`user.cc`和`user.h`里面提供了两个非常重要的类，供c++程序使用，其中`UserServiceRpc_stub`类
给`caller`使用，`UserServiceRpc_stub:Login()`发起远端调用，而`callee`则继承`UserServiceRpc`类并重写`UserServiceRpc:Login()`函数，实现
**Login函数调用处理**的逻辑。
- 具体作用和目的如下：
> 客户端caller调用远端方法Login和Register。Callee中的Login函数接收一个LoginRequest消息体，执行 完Login逻辑后将处理结果填写进LoginResponse消息体，再返回给Caller。调用Register函数的过程同理。


# 编写利用继承ProtoBuf协议的服务端callee作为服务端测试用例
- `class UserService : public Kuser::UserServiceRpc`// 继承自 protobuf 生成的 RPC 服务基类
-  成为RPC服务端
```cc
// 创建一个 RPC 服务提供者对象
    KrpcProvider provider;

    // 将 UserService 对象发布到 RPC 节点上，使其可以被远程调用
    provider.NotifyService(new UserService());

    // 启动 RPC 服务节点，进入阻塞状态，等待远程的 RPC 调用请求
    provider.Run();
```
- 简单分析以下：
1. 上面的类主要将客户端通过rpc远程调用请求的login方法，进行了处理将其响应的结果返回给客户端
2. 主要启动框架初始化（也就是导入在bin目录下的test.conf作为可执行程序后面的参数），其次在`notify（）`或者`run（）`中涉及到将`zookeeper`的客户端进行初始化连接到客户端的服务器，将服务器的服务对象`UserServiceRpc`和其`Login`、`Register`及服务器的`ip`和port发布到`zookeeper`进行管理，客户端也是一样的通过初始化`zookeeper`的客户端通过调用的`zookeeper`服务器，中服务器对象和方法，获取到存放在的ip和port，进行网络socket。通过动态多态就会走到login（）方法这里啦。

# 编写为服务器提供服务的函数
## 构建基础函数类----单例模式 `Krpcapplication`
1. 设计模式：单例模式。
2. 目的：这里的函数其目的是为了初始化框架，在我们执行可执行程序的时候必须跟上`-i`后面存放`zookeeper`服务器的`ip`和`port`及服务器ip和port, 并且这里还会调用`m_config.LoadConfigFile(config_file.c_str())`；将服务器的`ip`和`port`进行存放，并且对其字符串空字符进行删除。
3. 不管是客户端还是服务端都可以发现都是用了`KrpcApplication：：Init`,这里很正常.因为1服务器需要获取直接的ip和port，2客户端需要访问到`zookeeper`的ip和port，服务器需要获取到自己发布到网上的ip和port以及zookeeper的ip和port将服务对象和方法进行发布
## 获取和解析配置文件的类
`Krpcconfig`
## 服务器的主函数类，核心类----Krpcprovider
1. `NotifyService`注册服务对象及其方法，以便服务端能够处理客户端的RPC请求
  - 服务端需要知道客户端想要调用的服务对象和方法`ServiceInfo service_info;`
  - GetDescriptor() 方法会返回 protobuf 生成的服务类的描述信息（ServiceDescriptor）`const google::protobuf::ServiceDescriptor *psd = service->GetDescriptor()`
  - 遍历打印出有哪些服务信息并载入到服务`unordered_map`中
2. `Run`启动RPC服务节点，开始提供远程网络调用服务
  - 调用`KrpcApplication`的`GetConfig()`读取配置文件中的RPC服务器IP和端口
  - 使用muduo网络库，1创建地址对象，2创建TcpServer对象，3绑定连接回调和消息回调，分离网络连接业务和消息处理业务，4设置muduo库的线程数量
     + `muduo::net::InetAddress address(ip, port);`
     + `std::make_shared<muduo::net::TcpServer>(&event_loop, address, "KrpcProvider");`
     + `server->setConnectionCallback` `server->setMessageCallback`
     + `server->setThreadNum(4)`
  - 将当前RPC节点上要发布的服务全部注册到ZooKeeper上，让RPC客户端可以在ZooKeeper上发现服务
     + `zkclient.Start();`  // 连接ZooKeeper服务器
     + `zkclient.Create(service_path.c_str(), nullptr, 0);`// 创建服务节点
     - 作用：将当前服务节点的信息注册到ZooKeeper，供客户端发现服务。
    - 关键点：
         + ZK客户端启动：初始化Zkclient并启动与ZooKeeper的连接。
         + 注册服务路径：服务名称对应的永久节点路径：`/service_name`。方法名称对应的临时节点路径：`/service_name/method_name`
         + 临时节点：使用`ZOO_EPHEMERAL`标志，节点会在服务断开时自动删除。
3. `KrpcProvider::OnConnection`连接回调函数，处理客户端连接事件
4. `KrpcProvider::OnMessage`消息回调函数，处理客户端发送的RPC请求
     - 处理请求包括：从网络缓冲区中读取远程RPC调用请求的字符流，使用protobuf的CodedInputStream反序列化RPC请求，根据header_size读取数据头的原始字符流，反序列化数据，得到RPC请求的详细信息
     - 在RpcProvider:RunO函数中会用Muduo库提供网络模块监听Callee端的rpcserver的端口。当会对callee的rpcserver发起tcp连接rpcserver接收连接后，开启对客户端连接描述符的可读事件监听。caller将请求的服务方法及参数发给callee的rpcserver，此时rpcsercer上的muduo网络模块监听到该连接可读事件，然后就执行onMessage（）函数逻辑。
5. 生成RPC方法调用请求的request和响应的response参数
6. `KrpcProvider::SendRpcResponse`发送RPC响应给客户端
   - 这里提及其中一个重要的部分最后这个`NewCallback`的模板函数，并且返回一个 `google：:protobuf::closuer` 类的对象，该`Closure`类其实相当于一个闭包。这个闭包捕获成员对象的成员函数。也就是相当于执行`void RpcProvider::SendRpcResponse(conn, response);`，这个函数可以将`reponse`消息体发送给Tcp连接的另一端，即`caller`。
7. 析构函数，退出事件循环