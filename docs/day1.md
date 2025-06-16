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
## 构建基础函数类----单例模式
1. 设计模式：单例模式。
2. 目的：这里的函数其目的是为了初始化框架，在我们执行可执行程序的时候必须跟上`-i`后面存放`zookeeper`服务器的`ip`和`port`及服务器ip和port, 并且这里还会调用`m_config.LoadConfigFile(config_file.c_str())`；将服务器的`ip`和`port`进行存放，并且对其字符串空字符进行删除。
## 获取和解析配置文件的类
`Krpcconfig`
## 