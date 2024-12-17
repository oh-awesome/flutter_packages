class Singleton {
  // 私有成员变量，用于存储单例实例
  static final Singleton _instance = Singleton._internal();

  // 私有构造函数，防止外部创建实例
  Singleton._internal();

  // 静态工厂构造函数，返回单例实例
  static Singleton getInstance() {
    return _instance;
  }

  // 或者使用 getter 来简化访问
  static Singleton get instance => _instance;

  // 定义一些属性和方法
  String? data;

  void setData(String newData) {
    print('Setting data: $newData');
    data = newData;
  }

  String getData() {
    return data ?? 'No data';
  }
}