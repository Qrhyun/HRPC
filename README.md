# HRPC
## 项目概述
 本项目基于protobuf的c++分布式网络通信框架，使用了zookeeper作为服务中间件，负责解决在分布式服务部署中 服务的发布与调用、消息的序列与反序列化、网络包的收发等问题，使其能提供高并发的远程函数调用服务，可以让使用者专注于业务，快速实现微服务的分布式部署。

## 运行环境安装
```bash
./rpc_env.sh
```
> 
## 引入的库:
- muduo
- zookeeper
- protobuf
- Glog
## 运行环境：
ubuntu 22.04

## 项目构建
```sh
./rpc_build.sh
```

## 测试运行
```bash
./rpc_run.sh
```

## 结果
`server端`
![server](./image/server.png)
![server1](./image/server1.png)

`client端`
![client](./image/test.png)