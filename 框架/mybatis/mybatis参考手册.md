[TOC]

# mybatis快速入门

第一步、创建maven工程，导入依赖

```xml
<!--mybatis坐标-->
<dependency>
    <groupId>org.mybatis</groupId>
    <artifactId>mybatis</artifactId>
    <version>3.4.5</version>
</dependency>
<!--mysql驱动坐标-->
<dependency>    
    <groupId>mysql</groupId>   
    <artifactId>mysql-connector-java</artifactId>    
    <version>5.1.6</version>    
    <scope>runtime</scope>
</dependency>
<!--单元测试坐标-->
<dependency>    
    <groupId>junit</groupId>    
    <artifactId>junit</artifactId>    
    <version>4.12</version>    
    <scope>test</scope>
</dependency>
<!--日志坐标-->
<dependency>    
    <groupId>log4j</groupId>    
    <artifactId>log4j</artifactId>    
    <version>1.2.12</version>
</dependency>
```

第二步、创建数据库和编写java实体类

```sql
create table t_user(
	id int,
	username varchar(50),
	password varchar(50)
);
```

```java
public class User {    
	private int id;    
	private String username;    
	private String password;
    //省略get、set方法
}
```

第三步、编写用户表t_user对应的sql映射文件

UserMapper.XML

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper        
	PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"        
	"http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="userMapper">    
	<select id="findAll" resultType="com.itheima.domain.User">
		select * from User    
	</select>
</mapper>
```

第四步、编写MyBatis核心配置文件

```xml
<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Config 3.0//EN“ "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>    
    <!-- 废弃！！ -->
	<environments default="development">        
		<environment id="development">            
			<transactionManager type="JDBC"/>            
			<dataSource type="POOLED">                
				<property name="driver" value="com.mysql.jdbc.Driver"/>
				<property name="url" value="jdbc:mysql:///test"/>
				<property name="username" value="root"/>
				<property name="password" value="root"/>  
			</dataSource>
		</environment> 
	</environments>
	<mappers>
		<mapper resource="com/itheima/mapper/UserMapper.xml"/> 
	</mappers>
</configuration>
```

第五步、编写测试代码

```java
//加载核心配置文件
InputStream resourceAsStream = Resources.getResourceAsStream("SqlMapConfig.xml");
//获得sqlSession工厂对象
SqlSessionFactory sqlSessionFactory = new            
                           SqlSessionFactoryBuilder().build(resourceAsStream);
//获得sqlSession对象
SqlSession sqlSession = sqlSessionFactory.openSession();
//执行sql语句
List<User> userList = sqlSession.selectList("userMapper.findAll");
//打印结果
System.out.println(userList);
//释放资源
sqlSession.close();
```



# 核心配置讲解（挑重点去学习）

## 配置文件顺序(顺序必须保证！！)

```properties
configuration 配置 
	--- properties 属性
	--- settings 设置   通读一遍
	--- typeAliases 类型别名  ！！！
	--- typeHandlers 类型处理器
	--- objectFactory 对象工厂
	--- plugins 插件	！！！
	--- environments 环境  
		--- environment 环境变量
			--- transactionManager 事务管理器
			--- dataSource 数据源 
	--- databaseIdProvider 数据库厂商标识
	--- mappers 映射器  ！！！
```

## 属性（properties）

这些属性都是可外部配置且可动态替换的，既可以在典型的 Java 属性文件中配置，亦可通过 properties 元素的子元素来传递。例如：

```xml
<!-- 优先加载<property>标签，再去读取.properties配置-->
<properties resource="jdbc.properties">
  <property name="username" value="dev_user"/>
  <property name="password" value="F2Fa3!33TYyg"/>
</properties>
```

然后其中的属性就可以在整个配置文件中被用来替换需要动态配置的属性值。比如:         

```xml
<dataSource type="POOLED">
  <property name="driver" value="${driver}"/>
  <property name="url" value="${url}"/>
  <property name="username" value="${username}"/>
  <property name="password" value="${password}"/>
</dataSource>
```

这个例子中的 username 和 password 将会由 properties 元素中设置的相应值来替换。driver 和 url 属性将会由 config.properties 文件中对应的值来替换。这样就为配置提供了诸多灵活选择。

## 设置（settings）

这是 MyBatis 中极为重要的调整设置，它们会改变 MyBatis 的运行时行为。下表列出了一些常用的设置。

| 设置参数                  | 描述                                                         | 有效值                                          | 默认值                           |
| ------------------------- | ------------------------------------------------------------ | ----------------------------------------------- | -------------------------------- |
| cacheEnabled              | 全局地开启或关闭配置文件中的所有映射器已经配置的任何缓存。   | true \| false                                   | true                             |
| lazyLoadingEnabled        | 延迟加载的全局开关。当开启时，所有关联对象都会延迟加载。特定关联关系中可通过设置 `fetchType` 属性来覆盖该项的开关状态。 | true \| false                                   | false                            |
| defaultExecutorType       | 配置默认的执行器。SIMPLE 就是普通的执行器；REUSE 执行器会重用预处理语句（prepared statements）；BATCH 执行器将重用语句并执行批量更新。 | SIMPLE REUSE               BATCH                | SIMPLE                           |
| defaultStatementTimeout   | 设置超时时间，它决定驱动等待数据库响应的秒数。               | 任意正整数                                      | 未设置 (null)                    |
| mapUnderscoreToCamelCase  | 是否开启自动驼峰命名规则（camel case）映射，即从经典数据库列名 A_COLUMN 到经典 Java 属性名 aColumn 的类似映射. | true \| false                                   | false                            |
| localCacheScope           | MyBatis 利用本地缓存机制（Local Cache）防止循环引用（circular references）和加速重复嵌套查询。默认值为 SESSION，这种情况下会缓存一个会话中执行的所有查询。            若设置值为 STATEMENT，本地会话仅用在语句执行上，对相同 SqlSession 的不同调用将不会共享数据 | SESSION \| STATEMENT                            | SESSION                          |
| jdbcTypeForNull           | 当没有为参数提供特定的 JDBC 类型时，为空值指定 JDBC 类型。某些驱动需要指定列的 JDBC 类型，多数情况直接用一般类型即可，比如 NULL、VARCHAR 或 OTHER。 | JdbcType 常量，常用值：NULL, VARCHAR 或 OTHER。 | OTHER                            |
| returnInstanceForEmptyRow | 当返回行的所有列都是空时，MyBatis默认返回 `null`。当开启这个设置时，MyBatis会返回一个空实例。请注意，它也适用于嵌套的结果集 （如集合或关联）。（新增于 3.4.2） | true \| false                                   | false                            |
| lazyLoadTriggerMethods    | 指定对象的方法触发一次延迟加载                               | 如果是一个方法列表使用逗号分隔                  | toString、equal、clone、hashCode |
| aggressiveLazyLoading     | 当启用时，对任意延迟属性的调用会是带有延迟加载属性的对象完整加载；反之，每种属性将会按需加载 | true\|false                                     | true                             |

```xml
<!--  开启自动驼峰命名规则，对mybatis性能有一定的影响！！  -->
<settings>
  <setting name="mapUnderscoreToCamelCase" value="false"/>
</settings>
```

## 类型别名（typeAliases）

类型别名是为 Java 类型设置一个短的名字。存在的意义仅在于用来减少类完全限定名的冗余。例如：

```xml
<typeAliases>
  <typeAlias alias="Author" type="domain.blog.Author"/>
  <typeAlias alias="Blog" type="domain.blog.Blog"/>
</typeAliases>
```

也可以指定一个包名，MyBatis 会在包名下面搜索需要的 Java Bean，比如：

使用**类名**作为别名，别名匹配的时候**忽略大小写**的！！！         

```xml
<typeAliases>
  <package name="domain.blog"/>
</typeAliases>

```

这是一些为常见的 Java 类型内建的相应的类型别名。它们都是不区分大小写的，注意对基本类型名称重复采取的特殊命名风格。我们通过Mybatis的源码`org.apache.ibatis.type.TypeAliasRegistry`可以查看默认的类型别名。

|    别名    | 映射的类型 |
| :--------: | ---------- |
|   _byte    | byte       |
|   _long    | long       |
|   _short   | short      |
|    _int    | int        |
|  _integer  | int        |
|  _double   | double     |
|   _float   | float      |
|  _boolean  | boolean    |
|   string   | String     |
|    byte    | Byte       |
|    long    | Long       |
|   short    | Short      |
|    int     | Integer    |
|  integer   | Integer    |
|   double   | Double     |
|   float    | Float      |
|  boolean   | Boolean    |
|    date    | Date       |
|  decimal   | BigDecimal |
| bigdecimal | BigDecimal |
|   object   | Object     |
|    map     | Map        |
|  hashmap   | HashMap    |
|    list    | List       |
| arraylist  | ArrayList  |
| collection | Collection |
|  iterator  | Iterator   |

## 类型处理器（typeHandlers）

​	无论是 MyBatis 在预处理语句（PreparedStatement）中设置一个参数时，还是从结果集中取出一个值时，都会用类型处理器将获取的值以合适的方式转换成 Java 类型。下表描述了一些默认的类型处理器。我们可以在`org.apache.ibatis.type.TypeHandlerRegistry`查看

| 类型处理器                   | Java 类型                       |                          JDBC 类型                           |
| ---------------------------- | ------------------------------- | :----------------------------------------------------------: |
| `BooleanTypeHandler`         | `java.lang.Boolean`, `boolean`  |                    数据库兼容的 `BOOLEAN`                    |
| `ByteTypeHandler`            | `java.lang.Byte`, `byte`        |               数据库兼容的 `NUMERIC` 或 `BYTE`               |
| `ShortTypeHandler`           | `java.lang.Short`, `short`      |             数据库兼容的 `NUMERIC` 或 `SMALLINT`             |
| `IntegerTypeHandler`         | `java.lang.Integer`, `int`      |             数据库兼容的 `NUMERIC` 或 `INTEGER`              |
| `LongTypeHandler`            | `java.lang.Long`, `long`        |              数据库兼容的 `NUMERIC` 或 `BIGINT`              |
| `FloatTypeHandler`           | `java.lang.Float`, `float`      |              数据库兼容的 `NUMERIC` 或 `FLOAT`               |
| `DoubleTypeHandler`          | `java.lang.Double`, `double`    |              数据库兼容的 `NUMERIC` 或 `DOUBLE`              |
| `BigDecimalTypeHandler`      | `java.math.BigDecimal`          |             数据库兼容的 `NUMERIC` 或 `DECIMAL`              |
| `StringTypeHandler`          | `java.lang.String`              |                      `CHAR`, `VARCHAR`                       |
| `ClobReaderTypeHandler`      | `java.io.Reader`                |                              -                               |
| `ClobTypeHandler`            | `java.lang.String`              |                    `CLOB`, `LONGVARCHAR`                     |
| `NStringTypeHandler`         | `java.lang.String`              |                     `NVARCHAR`, `NCHAR`                      |
| `NClobTypeHandler`           | `java.lang.String`              |                           `NCLOB`                            |
| `BlobInputStreamTypeHandler` | `java.io.InputStream`           |                              -                               |
| `ByteArrayTypeHandler`       | `byte[]`                        |                    数据库兼容的字节流类型                    |
| `BlobTypeHandler`            | `byte[]`                        |                   `BLOB`, `LONGVARBINARY`                    |
| `DateTypeHandler`            | `java.util.Date`                |                         `TIMESTAMP`                          |
| `DateOnlyTypeHandler`        | `java.util.Date`                |                            `DATE`                            |
| `TimeOnlyTypeHandler`        | `java.util.Date`                |                            `TIME`                            |
| `SqlTimestampTypeHandler`    | `java.sql.Timestamp`            |                         `TIMESTAMP`                          |
| `SqlDateTypeHandler`         | `java.sql.Date`                 |                            `DATE`                            |
| `SqlTimeTypeHandler`         | `java.sql.Time`                 |                            `TIME`                            |
| `ObjectTypeHandler`          | Any                             |                     `OTHER` 或未指定类型                     |
| `EnumTypeHandler`            | Enumeration Type                | VARCHAR 或任何兼容的字符串类型，用以存储枚举的名称（而不是索引值） |
| `EnumOrdinalTypeHandler`     | Enumeration Type                | 任何兼容的 `NUMERIC` 或 `DOUBLE`   类型，存储枚举的序数值（而不是名称）。 |
| `SqlxmlTypeHandler`          | `java.lang.String`              |                           `SQLXML`                           |
| `InstantTypeHandler`         | `java.time.Instant`             |                         `TIMESTAMP`                          |
| `LocalDateTimeTypeHandler`   | `java.time.LocalDateTime`       |                         `TIMESTAMP`                          |
| `LocalDateTypeHandler`       | `java.time.LocalDate`           |                            `DATE`                            |
| `LocalTimeTypeHandler`       | `java.time.LocalTime`           |                            `TIME`                            |
| `OffsetDateTimeTypeHandler`  | `java.time.OffsetDateTime`      |                         `TIMESTAMP`                          |
| `OffsetTimeTypeHandler`      | `java.time.OffsetTime`          |                            `TIME`                            |
| `ZonedDateTimeTypeHandler`   | `java.time.ZonedDateTime`       |                         `TIMESTAMP`                          |
| `YearTypeHandler`            | `java.time.Year`                |                          `INTEGER`                           |
| `MonthTypeHandler`           | `java.time.Month`               |                          `INTEGER`                           |
| `YearMonthTypeHandler`       | `java.time.YearMonth`           |                                                              |
| `JapaneseDateTypeHandler`    | `java.time.chrono.JapaneseDate` |                            `DATE`                            |

你可以重写类型处理器或创建你自己的类型处理器来处理不支持的或非标准的类型。具体做法为：实现 `org.apache.ibatis.type.TypeHandler` 接口，或继承一个很便利的类 `org.apache.ibatis.type.BaseTypeHandler`，然后可以选择性地将它映射到一个 JDBC 类型。比如：

```java
public class MyDateTypeHandler extends BaseTypeHandler<Date> {
    public void setNonNullParameter(PreparedStatement preparedStatement, int i, Date date, JdbcType type) {
        preparedStatement.setString(i,date.getTime()+"");
    }
    public Date getNullableResult(ResultSet resultSet, String s) throws SQLException {
        return new Date(resultSet.getLong(s));
    }
    public Date getNullableResult(ResultSet resultSet, int i) throws SQLException {
        return new Date(resultSet.getLong(i));
    }
    public Date getNullableResult(CallableStatement callableStatement, int i) throws SQLException {
        return callableStatement.getDate(i);
    }
}
```

```xml
<!--注册类型自定义转换器-->
<typeHandlers>
    <typeHandler handler="com.itheima.typeHandlers.MyDateTypeHandler"></typeHandler>
</typeHandlers>
```

## 对象工厂（objectFactory）

​	MyBatis 每次创建结果对象的新实例时，它都会使用一个对象工厂（ObjectFactory）实例来完成。默认的对象工厂需要做的仅仅是实例化目标类，要么通过默认构造方法，要么在参数映射存在的时候通过参数构造方法来实例化。如果想覆盖对象工厂的默认行为，则可以通过创建自己的对象工厂来实现。比如：

```java
// ExampleObjectFactory.java
public class ExampleObjectFactory extends DefaultObjectFactory {
  public Object create(Class type) {
    return super.create(type);
  }
  public Object create(Class type, List<Class> constructorArgTypes, List<Object> constructorArgs) {
    return super.create(type, constructorArgTypes, constructorArgs);
  }
  public void setProperties(Properties properties) {
    super.setProperties(properties);
  }
  public <T> boolean isCollection(Class<T> type) {
    return Collection.class.isAssignableFrom(type);
  }
}
```

```xml
<!-- mybatis-config.xml 可以自定义对象工厂，基本不建议！！ -->
<objectFactory type="org.mybatis.example.ExampleObjectFactory">
    <property name="someProperty" value="100"/>
</objectFactory>
```

​	ObjectFactory 接口很简单，它包含两个创建用的方法，一个是处理默认构造方法的，另外一个是处理带参数的构造方法的。最后，setProperties 方法可以被用来配置 ObjectFactory，在初始化你的 ObjectFactory 实例后，objectFactory 元素体中定义的属性会被传递给 setProperties 方法。

## 环境配置（environments 直接忽略）

​	MyBatis 可以配置成适应多种环境，这种机制有助于将 SQL 映射应用于多种数据库之中，现实情况下有多种理由需要这么做。例如，开发、测试和生产环境需要有不同的配置；**不过要记住：尽管可以配置多个环境，但每个 SqlSessionFactory实例只能选择一种环境。**

```xml
<environments default="development"><!-- 指定默认使用的环境id -->
  <environment id="development"><!--设置环境id -->
    <!-- 配置事物管理器
			JDBC:	采用JDBC方式管理事务，在独立编码中常常使用
			MANAGED:采用容器方式管理事务，在JNDI数据源中常用		
	-->
    <transactionManager type="JDBC">
      <property name="..." value="..."/>
    </transactionManager>
    <!--配置数据源类型
		 UNPOOLED：非连接池，使用Mybatis提供的UnpooledDataSource实现
		 POOLED：连接池，使用Mybatis提供的PooledDataSource实现
		 JNDI：JNDI数据源，使用Mybatis提供的JndiDataSourceFactory实现
	-->
    <dataSource type="POOLED">
      <property name="driver" value="${driver}"/>
      <property name="url" value="${url}"/>
      <property name="username" value="${username}"/>
      <property name="password" value="${password}"/>
    </dataSource>
  </environment>
</environments>
```

## 数据库厂商标识（databaseIdProvider）

databaseIdProvider元素主要是为了支持不同厂商的数据库。配置如下： sql 分页 

```xml
	<!--数据库厂商标示 -->
    <databaseIdProvider type="DB_VENDOR">
        <property name="Oracle" value="oracle"/>
        <property name="MySQL" value="mysql"/>
        <property name="DB2" value="db2"/>
    </databaseIdProvider>
```

下面我们就可以在自己的sql语句中使用属性databaseId来标示数据库类型了。如下：

```xml

<select id="getAllUser" resultType="product" databaseId="mysql">
        SELECT * FROM user limit 0,10
</select>

```

```xml
<insert id="insert">
    <if test="_databaseId == 'oracle'">
        insert into users values (#{id}, #{name})
    </if>
    <if test="_databaseId == 'db2'">
        insert into users values (#{id}, #{name})
    </if>
</insert>
```



## 映射器（mappers ）

该标签的作用是加载映射文件的，加载方式有如下几种：

```xml
<!-- 使用相对于类路径的资源引用 -->
<mappers>
  <mapper resource="org/mybatis/builder/AuthorMapper.xml"/>
    ......
</mappers>


<!-- 使用完全限定资源定位符（URL） -->
<mappers>
  <mapper url="file:///var/mappers/AuthorMapper.xml"/>
    ......
</mappers>

<!-- 
	 使用映射器接口实现类的完全限定类名
 	 此种方法要求mapper接口名称和mapper映射文件名称相同，且放在同一个目录中
-->
<mappers>
  <mapper class="org.mybatis.builder.UserMapper"/>
    ......
</mappers>

<!-- 
	将包内的映射器接口实现全部注册为映射器 
	此种方法要求mapper接口名称和mapper映射文件名称相同，且放在同一个目录中
-->
<mappers>
  <package name="org.mybatis.builder"/>
    ......
</mappers>
```

# Mybatis映射文件

## 查询标签select

```xml
<!-- -->
<select id="findAll" resultType="com.itheima.domain.User">
	select * from User    
</select>
```

## 插入标签insert

```xml
<!-- flushCache:配置在调用SQL后，是否要求Myabatis清空之前查询的本地缓存和二级存储 -->
<insert id="add" parameterType="com.itheima.domain.User" flushCache="true">        
	insert into user values(#{id},#{username},#{password})    
</insert>
```

### 主键返回

​	有时候我们在插入数据的时候，主键是由数据库生成的。而且，我们执行完插入操作的代码后，需要使用到当前插入数据的主键ID，那么我们应该怎么办呢？？此时，我们就需要使用Mybatis给我们提供的主键返回功能了。具体如下：

情形一、使用数据库自增生成主键。

```xml
<insert id="add" parameterType="com.itheima.domain.User" >  
	<selectKey keyProperty="id" resultType="int" order="AFTER">
        select last_insert_id();
    </selectKey>
	insert into user values(null,#{username},#{password})    
</insert>
或
<insert id="add" parameterType="com.itheima.domain.User" useGeneratedKeys="true" keyColumn="id" keyProperty="id" >  
	insert into user values(null,#{username},#{password})    
</insert>
```

情形二、使用数据库UUID函数生成主键

```xml
<insert id="add" parameterType="com.itheima.domain.User"> 
    <selectKey keyProperty="id" resultType="string" order="BEFORE">
        select uuid();
    </selectKey>
	insert into user values(#{id},#{username},#{password})    
</insert>
```

## 更新标签update

```xml
<update id="update" parameterType="com.itheima.domain.User">
   	update user set username=#{username},password=#{password} where id=#{id
</update>
```

## 删除标签delete

```xml
<delete id="delete" parameterType="java.lang.Integer">
	delete from user where id=#{id}
</delete>
```

# 动态sql

​	MyBatis 的强大特性之一便是它的动态 SQL。如果你有使用 JDBC 或其它类似框架的经验，你就能体会到根据不同条件拼接 SQL 语句的痛苦。例如拼接时要确保不能忘记添加必要的空格，还要注意去掉列表最后一个列名的逗号。利用动态 SQL 这一特性可以彻底摆脱这种痛苦。

## if判断

```xml
<select id="findByCondition" parameterType="user" resultType="user">
    select * from User where 1=1
        <if test="id!=0">
            and id=#{id}
        </if>
        <if test="username!=null">
            and username=#{username}
        </if>
</select>
```

## choose, when, otherwise

有时我们不想应用到所有的条件语句，而只想从中择其一项。针对这种情况，MyBatis 提供了 choose 元素，它有点像 Java 中的 switch 语句。

```xml
<select id="findUsers" parameterType="user" resultType="user">
  SELECT * FROM user WHERE 1=1
  <choose>
    <when test="id != null and id >0">
      AND id = #{id}
    </when>
    <when test="username != null and username != '' ">
      AND username like #{username}
    </when>
    <otherwise>
      AND password is not null
    </otherwise>
  </choose>
</select>
```

## trim, where, set

where元素只会在至少有一个子元素的条件返回 SQL 子句的情况下才去插入“WHERE”子句。而且，若语句的开头为“AND”或“OR”，*where* 元素也会将它们去除。

```xml
<select id="findByCondition" parameterType="user" resultType="user">
    select * from User
    <where>
        <if test="id!=0">
            and id=#{id}
        </if>
        <if test="username!=null">
            and username=#{username}
        </if>
    </where>
</select>
```

以上的where标签可以使用自定义的trim标签来实现相同的功能

```xml
<trim prefix="WHERE" prefixOverrides="AND">
   <if test="id!=0">
            and id=#{id}
   </if>
   <if test="username!=null">
            and username=#{username}
  </if>
</trim>
<!---相当于where标签 -->
```

类似的用于动态更新语句的解决方案叫做 *set*。*set* 元素可以用于动态包含需要更新的列，而舍去其它的。比如：

```xml
<update id="updateAuthorIfNecessary">
  update user
    <set>
      <if test="username != null">username=#{username},</if>
      <if test="password != null">password=#{password},</if>
    </set>
  where id=#{id}
</update>
```

以上的where标签可以使用自定义的trim标签来实现相同的功能

```xml
<trim prefix="SET" suffixOverrides=",">
   <if test="username != null">username=#{username},</if>
   <if test="password != null">password=#{password},</if>
</trim>
<!-- 相当于set标签--->
```

## foreach

动态 SQL 的另外一个常用的操作需求是对一个集合进行遍历，通常是在构建 IN 条件语句的时候。比如：

```xml
<select id="findByIds" parameterType="list" resultType="user">
    select * from User
    <where>
        <foreach collection="array" open="id in(" close=")" item="id" separator=",">
            #{id}
        </foreach>
    </where>
</select>
```

foreach标签的属性含义如下：

```
•	<foreach>标签用于遍历集合，它的属性：
•	collection：代表要遍历的集合元素，注意编写时不要写#{}
•	open：代表语句的开始部分
•	close：代表结束部分
•	item：代表遍历集合的每个元素，生成的变量名
•	sperator：代表分隔符
```



# Mybatis参数传递与结果封装

## 1、参数传递

### 1.1、单个参数：

```xml
<select id="getUserById" parameterType="int" resultType="com.itheima.domain.User" >
	select * from t_user where id=#{id}
</select>
```

### 1.2、多个参数

javaBean传参

```xml
<insert id="insertUser" parameterType="com.itheima.domain.User" >
	  insert into t_user(username,password,nick_name)
	  values( #{username},#{password},#{nick_name} )
</insert>
```

map集合传参

```xml
<insert id="insertUser" parameterType="map" >
	  insert into t_user(username,password,nick_name)
	  values( #{username},#{password},#{nick_name} )
</insert>
```

通过@Param方式传参(参数不多，但是>1)

```xml
<!--
接口方法定义如下：
	findUserByUsername(@Param("username") String username,@Param("id") int id )
-->
<select id="findUserByUsername" resultType="com.itcast.domain.User">
		select * from user where username like concat('%',#{username},'%') or id=#{id}
</select>
```

通过param1、param2...paramN

```xml
<!-- 注意顺序要与方法的参数顺序一致，此种方式不需要指定parameterType类型 -->
<select id="findUserByUsername" resultType="com.itcast.domain.User" >
	select * from user where username like concat('%',#{param1},'%') or id=#{param2}
</select>
```

### 1.3、#和$的区别 必须知道！！

​	1、#对传入的参数视为字符串，也就是它会预编译，select * from user where name = #{name}，比如我传一个csdn，那么传过来就是 select * from user where name = 'csdn'；

​	2、$将不会将传入的值进行预编译，select * from user where name=csdn，比如我穿一个csdn，那么传过来就是 select * from user where name=csdn；

​	3、#的优势就在于它能很大程度的防止sql注入，而$则不行。

比如：用户进行一个登录操作，后台sql验证式样的：select * from user where username=#{name} and password = #{pwd}，如果前台传来的用户名是“wang”，密码是 “1 or 1=1”，用#的方式就不会出现sql注入，而如果换成$方式，sql语句就变成了 select * from user where username=wang and password = 1 or 1=1。这样的话就形成了sql注入。

​	4、MyBatis中会存在一些不得不使用$的情形。比如：动态传递查询的表名，动态传递查询的字段等待。如下：

```
select * from ${tableName} 
```

在使用$我们一定要做好防止sql注入的工作，比如可以在代码中对传递的参数进行，对包含一些sql语法关键字的参数进行过滤，如1=1 delete truncate等待。



## 2、结果封装

### 2.1、resultType封装

1、基本的数据类型封装：如

```xml
<select id="getUserCount" resultType="int">
	select count(*) from t_user
</select>
```

2、JavaBean类型数据的封装：如

```xml
<select id="findUserByUsername" parameterType="string" resultType="com.itcast.domain.User">
	select * from t_user where user_name like concat('%',#{username},'%')
</select>
```

3、map类型数据的封装，返回map类型的数据，map的key就是查询sql的列名

```xml
<select id="findUserByUsername" parameterType="string" resultType="map ">
	select * from t_user where user_name like concat('%',#{username},'%')
</select>
```

表的列名跟属性名不一致的解决方案 :

1.	查询sql语句中使用别名;
2.	使用resultMap：指定表的列名跟实体类的属性名的对应关系;
3.	使用mybatis的自动驼峰命名法匹配。

### 2.2、resultMap封装

​	主要用于解决数据库中表的列名与实体类的属性名称不一致的问题，resultMap还可以用于解决mybatis中一对一、一对多和多对多数据封装的问题。

#### 1、 一对一数据的封装

使用用户订单模型

```sql
-- 建表语句
create table t_user (
	id int,
	username varchar(20),
	password varchar(20),
);
create table t_orders(
	id int,
	ordertime datetime,
	total double,
	uid int
);
```

```java
//实体类
public class Order {
    private int id;
    private Date ordertime;
    private double total;
    //代表当前订单从属于哪一个客户
    private User user;
}

public class User {
    private int id;
    private String username;
    private String password;
    
    //代表当前用户具备哪些订单
    private List<Order> orderList;
}
```

编写mapper映射

```xml
	<resultMap id="orderMap" type="com.itheima.domain.Order">
        <id column="oid" property="id"></id>
        <result column="ordertime" property="ordertime"></result>
        <result column="total" property="total"></result>
        
        <result column="uid" property="user.id"></result>
        <result column="username" property="user.username"></result>
        <result column="password" property="user.password"></result>
    </resultMap>
    <select id="findAll" resultMap="orderMap">
        select *,o.id oid from t_orders o,t_user u where o.uid=u.id
    </select>
```

或

```xml
<resultMap id="orderMap" type="com.itheima.domain.Order">
    <result property="id" column="id"></result>
    <result property="ordertime" column="ordertime"></result>
    <result property="total" column="total"></result>
    <association property="user" javaType="com.itheima.domain.User">
        <result column="uid" property="id"></result>
        <result column="username" property="username"></result>
        <result column="password" property="password"></result>
    </association>
</resultMap>
    <select id="findAll" resultMap="orderMap">
        select *,o.id oid from t_orders o,t_user u where o.uid=u.id
    </select>
```

或

```xml
	<resultMap type="orders" id="order_user_resultmap">
		<id property="id" column="id"/>
		<result property="ordertime" column="ordertime"></result>
    	<result property="total" column="total"></result>
		<!-- 配置一对一关联映射 -->
		<!--  	fetchType="lazy" 开启懒加载
				column：指定需要传递给下一个sql的参数列
				select：指定封装user数据的查询sql
		-->
		<association property="user" column="uid"  fetchType="lazy"
			javaType="com.itheima.domain.User" select="selectUserByOrderId">
		</association>
	</resultMap>
	<!-- 查询订单数据 -->
	<select id="getOrders" parameterType="int" resultMap="order_user_resultmap">
		select * from t_orders where id = #{id}
	</select>
	<!-- 查询用户数据 -->
	<select id="selectUserByOrderId" parameterType="int" resultType="user">
		select * from t_user where id = #{id}
	</select>

```

#### 2、一对多数据的封装

使用用户订单模型(同上)

编写mapper映射

```xml
	<resultMap id="userMap" type="com.itheima.domain.User">
        <result column="id" property="id"></result>
        <result column="username" property="username"></result>
        <result column="password" property="password"></result>
        <!-- 配置一对多关联映射 -->
		<!-- property：对于user对象中的集合属性 -->
		<!-- ofType：集合中每个元素的数据类型 -->
        <collection property="orderList" ofType="com.itheima.domain.Order">
            <result column="oid" property="id"></result>
            <result column="ordertime" property="ordertime"></result>
            <result column="total" property="total"></result>
        </collection>
    </resultMap>
    <select id="findAll" resultMap="userMap">
        select *,o.id oid from user u left join orders o on u.id=o.uid
    </select>
```

或

```xml
	<resultMap type="user" id="user_order_resultmap">
		<id property="id" column="id"/>
		<result property="username" column="username"/>
        <result column="password" property="password"></result>
		<!-- 配置一对多关联映射 -->
		<!-- property：对于user对象中的集合属性 -->
		<!-- ofType：集合中每个元素的数据类型  fetchType="lazy" ： 开启懒加载-->
		<collection property="orders" fetchType="lazy" ofType="orders"  column="id" select="getOrderOnUser">
		</collection>
	</resultMap>
	
	<select id="getUserWithOrders" resultMap="user_order_resultmap">
		SELECT * FROM t_user
	</select>
	
	<select id="getOrderOnUser" resultType="orders" parameterType="int">
		SELECT o.* FROM `t_orders` o where o.user_id = #{id}
	</select>

```

#### 3、多对多数据封装

使用用户与角色模型

```sql
create table sys_role(
	id int,
	rolename varchar(50)
)

create table sys_user_role(
	user_id int,
	role_id int
)
```

```java
public class Role {
    private int id;
    private String rolename;
}
```

```xml
<resultMap id="userRoleMap" type="com.itheima.domain.User">
    <result column="id" property="id"></result>
    <result column="username" property="username"></result>
    <result column="password" property="password"></result>
    <result column="birthday" property="birthday"></result>
    <collection property="roleList" ofType="com.itheima.domain.Role">
        <result column="rid" property="id"></result>
        <result column="rolename" property="rolename"></result>
    </collection>
</resultMap>
<select id="findAllUserAndRole" resultMap="userRoleMap">
    select u.*,r.*,r.id rid from user u left join user_role ur on u.id=ur.user_id
    inner join role r on ur.role_id=r.id
</select>
```

或



# Mybatis缓存

​	像大多数的持久化框架一样，Mybatis 也提供了缓存策略，通过缓存策略来减少数据库的查询次数，从而提
高性能。Mybatis 中缓存分为一级缓存，二级缓存。

## 一级缓存(默认开启)

​	一级缓存是**SqlSession级别**的缓存，它是默认开启的。我们使用同一个SqlSession对象调用同一个Mapper方法，往往只执行一次SQL，因为使用SqlSession查询后，mybatis会默认将其存入一级缓存中，当下一次在查询的时候，如果缓存中有数据，就会直接从缓存中取数，而不会再去访问数据库了。

​	当调用 SqlSession 的修改，添加，删除，commit()，close()等方法时，就会清空一级缓存。

## 二级缓存(默认不使用)

​	Mybatis的二级缓存是**SqlSessionFactory级别**的缓存，默认不开启，二级缓存的开启需要配置，实现二级缓存的时候，mybatis要求返回的POJO对象，**必须实现序列化**。

​	那么如何开启二级缓存呢，方法很简单，只需要在编写sql的mapper.xml文件中配置如下标签：

```xml
<cache />
```

这样的一个语句里面，很多设置都是默认的，如果我们只是这样配置，那么意味着：

​	Ø  当前映射文件中的所有select语句将会被缓存。

​	Ø  当前映射文件中的所有insert、update、delete语句会刷新缓存。

设置缓存标签cache的其他选项：

```xml
<cache eviction="LRU" flushInterval="1000" size="1024" readOnly="true"></cache>
<!--
eviction：缓存的回收策略
    LRU - 最近最少使用，移除最长时间不被使用的对象
    FIFO - 先进先出，按对象进入缓存的顺序来移除它们
    SOFT - 软引用，移除基于垃圾回收器状态和软引用规则的对象
    WEAK - 弱引用，更积极地移除基于垃圾收集器和弱引用规则的对象

flushInterval：缓存刷新间隔
	缓存多长时间清空一次，默认不清空

size：缓存可以存放多少个元素 

readOnly：是否只读
	true：只读
	mybatis认为所有从缓存中获取数据的操作都是只读操作，不会修改数据。mybatis为了加快获取数据，直接就会将数据在缓存中的引用交给用户 。不安全，速度快
	false：读写(默认)：
	mybatis觉得获取的数据可能会被修改mybatis会利用序列化&反序列化的技术克隆一份新的数据给你。安全，速度相对慢
-->

```

其实如果想要上面的二级缓存设置有效，我们还需要在 SqlMapConfig.xml  文件开启二级缓存，配置如下：

```xml
<settings>
	<!-- 开启二级缓存的支持 -->
	<setting name="cacheEnabled" value="true"/>
</settings>
```

因为 cacheEnabled 的取值默认就为 true，所以这一步可以省略不配置。为 true 代表开启二级缓存；为false
代表不开启二级缓存。

# mybatis 注解开发

## mybatis常用注解

```
#基本的CURD
	@Insert:实现新增
	@Update:实现更新
	@Delete:实现删除
	@Select:实现查询
#多表查询的注解
	@Result:实现结果集封装
	@Results:可以与@Result 一起使用，封装多个结果集
	@ResultMap:实现引用@Results 定义的封装
	@One:实现一对一结果集封装
	@Many:实现一对多结果集封装

	@SelectProvider:实现动态 SQL 映射
	@InsertProvider
	@UpdateProvider
	@DeleteProvider
	@CacheNamespace:实现注解二级缓存的使用
   @SelectKey
```

## 使用注解实现基本 CRUD

```java
	@Insert("insert into user values(#{id},#{username},#{password},#{birthday})")
    public void save(User user);

    @Update("update user set username=#{username},password=#{password} where id=#{id}")
    public void update(User user);

    @Delete("delete from user where id=#{id}")
    public void delete(int id);

    @Select("select * from user where id=#{id}")
    public User findById(int id);

    @Select("select * from user")
    public List<User> findAll();
```

### 一对一

```java
 	@Select("select * from orders")
    @Results({
            @Result(id=true,property = "id",column = "id"),
            @Result(property = "ordertime",column = "ordertime"),
            @Result(property = "total",column = "total"),
            @Result(property = "user",column = "uid",
                    javaType = User.class,
                    one = @One(select = "com.itheima.mapper.UserMapper.findById"))
    })
    List<Order> findAll();

	public interface UserMapper {
    	@Select("select * from user where id=#{id}")
    	User findById(int id); 
	}
```

### 一对多

```java
public interface UserMapper {
    @Select("select * from user")
    @Results({
            @Result(id = true,property = "id",column = "id"),
            @Result(property = "username",column = "username"),
            @Result(property = "password",column = "password"),
            @Result(property = "birthday",column = "birthday"),
            @Result(property = "orderList",column = "id",
                    javaType = List.class,
                    many = @Many(select = "com.itheima.mapper.OrderMapper.findByUid"))
    })
    List<User> findAllUserAndOrder();
}

public interface OrderMapper {
    @Select("select * from orders where uid=#{uid}")
    List<Order> findByUid(int uid);

}
```

### 多对多

```java
public interface UserMapper {
    @Select("select * from user")
    @Results({
        @Result(id = true,property = "id",column = "id"),
        @Result(property = "username",column = "username"),
        @Result(property = "password",column = "password"),
        @Result(property = "birthday",column = "birthday"),
        @Result(property = "roleList",column = "id",
                javaType = List.class,
                many = @Many(select = "com.itheima.mapper.RoleMapper.findByUid"))
})
List<User> findAllUserAndRole();}



public interface RoleMapper {
    @Select("select * from role r,user_role ur where r.id=ur.role_id and ur.user_id=#{uid}")
    List<Role> findByUid(int uid);
}
```

# Mybatis plugins插件(装X)

## 分页插件PageHelper使用（会用！！！！）

第一步、导入通用PageHelper坐标

```xml
<!-- 分页助手 -->
<dependency>
    <groupId>com.github.pagehelper</groupId>
    <artifactId>pagehelper</artifactId>
    <version>3.7.5</version>
</dependency>
<dependency>
    <groupId>com.github.jsqlparser</groupId>
    <artifactId>jsqlparser</artifactId>
    <version>0.9.1</version>
</dependency>
```

第二步、在mybatis核心配置文件中配置PageHelper插件

```xml
<!-- 注意：分页助手的插件  配置在通用馆mapper之前 -->
<plugin interceptor="com.github.pagehelper.PageHelper">
    <!-- 指定方言 -->
    <property name="dialect" value="mysql"/>
</plugin>
```

第三步、分页代码实现

```java
@Test
public void testPageHelper(){
    //设置分页参数
    PageHelper.startPage(3,2);
    // select * from user	
    List<User> select = userMapper2.select(null);
    
    for(User user : select){
        System.out.println(user);
    }
}
//其他分页的数据
PageInfo<User> pageInfo = new PageInfo<User>(select);
System.out.println("总条数："+pageInfo.getTotal());
System.out.println("总页数："+pageInfo.getPages());
System.out.println("当前页："+pageInfo.getPageNum());
System.out.println("每页显示长度："+pageInfo.getPageSize());
System.out.println("是否第一页："+pageInfo.isIsFirstPage());
System.out.println("是否最后一页："+pageInfo.isIsLastPage());
```

## 自定义分页插件

### 一、Mybatis的插件概述

要理解mybatis的插件技术，必须首先知道Mybatis的执行过程：

![](img\mybatis原理图.jpg)

通过上图描述我们知道mybatis的数据库访问是通过sqlSession的四大对象完成的。我们可以在四大对象调用的时候插入我们自定义的代码逻辑，去执行一些特殊的要求以满足特殊场景的需求，这就是Mybatis的插件技术。

### 二、如何自定义Mybatis插件

**步骤一、编写自己的插件类**

这个类需要实现Mybatis提供的插件接口Interceptor。在这个接口中定义了三个方法。

```java
public interface Interceptor {

    //它将直接覆盖你所拦截对象原有的方法，是插件的核心方法。该方法会传入一个Invocation对象，通过它就可以反射调用原来对象的方法
    Object intercept(Invocation invocation) throws Throwable;

    //传入的target参数就是被拦截的对象。它的作用是给被拦截的对象生成一个代理对象，并返回它
    Object plugin(Object target);

    //允许在配置插件时的plugin元素中配置所需要的参数，方法在插件初始化的时候就被调用了一次，然后把插件对象注入到配置中，以便后面再取出。
    void setProperties(Properties properties);
}
```

**步骤二、确定插件需要拦截的签名**

正如Mybatis插件可以拦截SqlSession中的**四大对象**中的任意一个一样。插件需要注册签名才能够运行。注册签名时需要确定以下几个因素：

1、确定需要拦截的对象。

- Executor执行器，它负责调度执行SQL的全过程，一般很少拦截它。
- StatementHandler，是执行SQL的过程，拦截它可以重写我们的SQL，这个是最常用的拦截对象。
- ParameterHandler，很明显它主要是拦截执行SQL的参数组装，你可以重写组装参数的规则。
- ResultSetHandler，用于拦截执行结果的组装，拦截它，我们可以重写组装结果的规则。

2、拦截方法和参数

当你确定了需要拦截的对象，接下来就要确定需要拦截该对象的什么方法及方法的参数。例如，我们现在需要自定义分页插件，那么我们肯定需要去修改执行的SQL，也就是说我们需要拦截StatementHandler对象。我们知道StatementHandler的prepare方法会预编译SQL，于是我们需要拦截的方法便是prepare方法，在此之前完成SQL的重写编写。那么我们现在已经确定了拦截StatementHandler的prepare方法，方法中有一个参数Connection对象，因此我们可以确定我们插件类的签名如下：

```java
@Intercepts({ 
	@Signature(type = StatementHandler.class, //插件拦截的对象
			method = "prepare", //插件拦截的对象的哪个方法
			args = { Connection.class }) //拦截的方法的参数
	})
public class MyInterceptor implements Interceptor{......
```

**步骤三、实现拦截的方法**

```java
public interface Interceptor {
  Object intercept(Invocation invocation) throws Throwable;
}
```

### 三、自定义插件实现分页功能

分页插件是Mybatis中最为经典和常用的插件，要定义插件首先需要确定插件需要拦截的对象。我们知道Mybatis中SQL的预编译是在StatementHandler对象的prepare方法中进行的，因此我们需要在此方法之前去创建计算总数的SQL，并且通过它查询总条数，然后将当前要运行的SQL改造为分页SQL，这样就能进行分页查询了。

**1、为了方便分页插件的使用，需要先定义一个POJO对象，用来封装分页需要的数据。**

```java
public class PageParams {
    private Integer page;//当前页码
    private Integer pageSize;//每页条数
    private Boolean useFlag;//是否启用插件
    private Boolean checkFlag;//是否检查当前页码有效性
    private Integer total;//当前SQL返回总数，插件回填
    private Integer totalPage;//总页数，插件回填
    //set和get方法。。。。。
}
```

**2、定义分页插件类PagingPlugin实现Interceptor接口**

```java
@Intercepts({
        @Signature(type = StatementHandler.class,//插件拦截的对象
                method = "prepare", //插件拦截的对象的方法
                args = { Connection.class }) //拦截的方法的参数
})
public class PagingPlugin implements Interceptor {
    private Integer defaultPage;//默认分页
    private Integer defaultPageSize;//默认每页条数
    private Boolean defaultUseFlag;//默认是否启动插件
    private Boolean defaultCheckFlag;//默认是否检测当前页码的有效性
    private String dbType = "mysql";//数据库类型，默认mysql
    //TODO
}
```

**3、实现Interceptor的plugin方法去生成代理对象**

```java
	/**
     * 生成代理对象
     */
    public Object plugin(Object statementHandler) {
        return Plugin.wrap(statementHandler, this);;
    }
```

**4、实现setProperties方法，去设置配置参数**

```java
	/**
	 * 初始化参数
	 */
	@Override
	public void setProperties(Properties props) {
		String defaultPage = props.getProperty("default.page","1");
		String defaultPageSize = props.getProperty("default.pageSize","20");
		String defaultUseFlag = props.getProperty("default.useFlag","false");
		String defaultCheckFlag = props.getProperty("default.checkFlag","false");
		this.defaultPage = Integer.parseInt(defaultPage);
		this.defaultPageSize = Integer.parseInt(defaultPageSize);
		this.defaultUseFlag = Boolean.parseBoolean(defaultUseFlag);
		this.defaultCheckFlag = Boolean.parseBoolean(defaultCheckFlag);
	}
```

**5、实现intercept方法，这是实现我们分页逻辑的重点**

```java
@Override
public Object intercept(Invocation invocation) throws Throwable {
    //分离代理对象，获取最原始的被代理类
	MetaObject metaStatementHandler= getUnProxyObject(invocation);
	//取出需要执行的sql
	String sql = (String) metaStatementHandler.getValue("delegate.boundSql.sql");
	if(!checkSelect(sql)){//判断是否是select语句，如果不是，则不做处理
		return invocation.proceed();
	}
	BoundSql boundSql = (BoundSql) metaStatementHandler.getValue("delegate.boundSql");
	Object parameterObject = boundSql.getParameterObject();
    //获取分页数据PageParams
	PageParams pageParams = getPageParams(parameterObject);
	if(pageParams == null){//没有分页参数，不启用插件
		return invocation.proceed();
	}
	
	//获取分页参数，如果获取不到，则使用默认值
	Integer pageNum = pageParams.getPage()==null?this.defaultPage:pageParams.getPage();
	Integer pageSize = pageParams.getPageSize() == null? this.defaultPageSize:pageParams.getPageSize();
	Boolean useFlag = pageParams.getUseFlag() == null?this.defaultUseFlag:pageParams.getUseFlag();
	Boolean checkFlag = pageParams.getCheckFlag() == null?this.defaultCheckFlag:pageParams.getCheckFlag();
	if(!useFlag){//不使用分页插件
		return invocation.proceed();	
	}
	//获取总记录数
	int total = getTotal(invocation,metaStatementHandler,boundSql);
	//回填总数到分页参数中
	this.SetTotalToPageParams(pageParams, total, pageSize);
	//检查当前页码有效性
	this.checkPage(checkFlag, pageNum, pageParams.getTotalPage());		
	return changeSQL(invocation, metaStatementHandler, boundSql, pageNum, pageSize);
}
```

首先需要从代理对象中分离出真实对象，通过MetaObject绑定这个非代理对象来获取各种参数，这是插件中常常用到的方法。getUnProxyObject方法就是用来获取真实对象的。

```java
/**
 * 从代理对象中分离出真实对象
 * @param invocation
 * @return
 */
private MetaObject getUnProxyObject(Invocation invocation) {
	StatementHandler statementHandler = (StatementHandler) invocation.getTarget();
	MetaObject metaStatementHandler= SystemMetaObject.forObject(statementHandler);
	while(metaStatementHandler.hasGetter("h")){
		Object object = metaStatementHandler.getValue("h");
		metaStatementHandler = SystemMetaObject.forObject(object);
	}
	
	while(metaStatementHandler.hasGetter("target")){
		Object object = metaStatementHandler.getValue("target");
		metaStatementHandler = SystemMetaObject.forObject(object);
	}
	return metaStatementHandler;
}
```

这里从BoundSql中获取我们当前要执行的SQL，如果是select语句我们才会进行分页处理，否侧直接通过反射执行原有的方法，所以这里需要做一个判断，代码如下

```java
/**
 * 判断是否是Select语句
 * @param sql
 * @return
 */
private boolean checkSelect(String sql) {
	String trimSql = sql.trim();
	int idx = trimSql.toLowerCase().indexOf("select");
	return idx==0;
}
```

这个时候需要获取分页参数。参数可以是Map对象，也可以是POJO，或者是@Param注解。这里支持继承PageParams或者Map，其实@Param在Mybatis也是一种Map传参。以下是获取分页参数的方法getPageParams：

```java
/**
 *
 */
private PageParams getPageParams(Object parameterObject) {
	if(parameterObject == null){
		return null;
	}
	PageParams pageParams = null;
	if(parameterObject instanceof Map){//如果是Map，则遍历Map找到分页参数PageParams
		Map<String,Object> paramMap = (Map<String, Object>) parameterObject;
		Set<String> keySet = paramMap.keySet();
		Iterator<String> iterator = keySet.iterator();
		while(iterator.hasNext()){
			String key = iterator.next();
			Object value = paramMap.get(key);
			if(value instanceof PageParams){
				return (PageParams) value;
			}
		}
	}else if(parameterObject instanceof PageParams){//如果不是Map，就判断它是不是PageParams类，如果是则直接返回
		pageParams = (PageParams) parameterObject;
	}
	return pageParams;
}
```

得到分页参数后，就要获取总记录数，方法如下

```java
/**
 * 获取总记录数
 * @param invocation
 * @param metaStatementHandler
 * @param boundSql
 * @return
 */
private int getTotal(Invocation invocation, MetaObject metaStatementHandler, BoundSql boundSql) {
	//获取当前的mappedStatement
	MappedStatement mappedStatement = (MappedStatement) metaStatementHandler.getValue("delegate.mappedStatement");
	//获取配置对象
	Configuration cfg = mappedStatement.getConfiguration();
	//获取当前需要执行的SQL
	String sql = (String) metaStatementHandler.getValue("delegate.boundSql.sql");
	String countSql = "select count(*) as \"total\" from ( "+sql+" ) ";
	//获取拦截方法参数，我们知道是Connection对象
	Connection connection = (Connection) invocation.getArgs()[0];
	PreparedStatement ps = null;
	int total = 0;
	try{
		//预编译统计总数SQL
		ps =  connection.prepareStatement(countSql);
		//构建统计总数BoundSql
		BoundSql countBoundSql = new BoundSql(cfg,countSql,boundSql.getParameterMappings(),boundSql.getParameterObject());
		//构建Mybatis的ParameterHandler用来设置查询总数SQL的参数
		ParameterHandler handler = new DefaultParameterHandler(mappedStatement, boundSql.getParameterObject(), countBoundSql);
		//设置查询总数参数
		handler.setParameters(ps);
		//执行查询
		ResultSet rs = ps.executeQuery();
		while(rs.next()){
			total = rs.getInt("total");
		}
	}catch(Exception e){
		
	}finally{
		if(ps != null){
			try {
				ps.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
	}
	System.err.println("总条数："+total);	
	return total;
}
```

得到这个总数后将它回填到分页参数中，这样我们就得到了分页数据中两个很重要的参数了总记录数和总页数。

```java
//回填总记录数和总页数
private void SetTotalToPageParams(PageParams pageParams,int total,int pageSize){
	pageParams.setTotal(total);
	int totalPage = total%pageSize==0?total/pageSize:total/pageSize+1;
	pageParams.setTotalPage(totalPage);
}
```

然后，根据分页参数的设置判断是否启用检测页码正确性的处理，如果当前页码大于最大页码的时候抛出异常，提示错误，代码如下：

```java
/**
 * 校验当前页码的有效性
 */
private void checkPage(Boolean checkFlag,Integer pageNum,Integer pageTotal) throws Exception{
	if(checkFlag){
		if(pageNum > pageTotal){
			throw new Exception("查询失败，查询页码"+pageNum+">查询总页数"+pageTotal);
		}
	}
}
```

最后我们修改当前SQL为分页SQL

```java
/**
 * 修改当前查询的sql
 */
private Object changeSQL(Invocation invocation,MetaObject metaStatementHandler,BoundSql boundSql,int page,int pageSize) throws Exception{
	//获取当前需要执行的SQL
	String sql = (String) metaStatementHandler.getValue("delegate.boundSql.sql");
	//修改SQL，根据数据库不同来编写分页SQL，在代码中只对mysql和oracle数据库做了判断。
	String newSql = "";
	if("mysql".equalsIgnoreCase(dbType)){
		newSql = "select * from ( "+sql+" ) temp limit ?,?";
	}else if("oracle".equalsIgnoreCase(dbType)){
		newSql = "select * from ( select temp.*,rownum rw from ( "+ sql+" ) temp where rownum<=? ) where rw>?";
	}
	//修改当前需要执行的SQL
	metaStatementHandler.setValue("delegate.boundSql.sql", newSql);
	//获取PrepareStatement，为其设置分页参数
	PreparedStatement ps = (PreparedStatement) invocation.proceed();
	int parameterCount = ps.getParameterMetaData().getParameterCount();
	if("mysql".equalsIgnoreCase(dbType)){
		ps.setInt(parameterCount-1, (page-1)*pageSize);
		ps.setInt(parameterCount, pageSize);
	}else if("oracle".equalsIgnoreCase(dbType)){
		ps.setInt(parameterCount-1, page*pageSize);
		ps.setInt(parameterCount, (page-1)*pageSize+1 );
	}
	return ps;
}
```

这样我们的分页插件就完成了。接下来就是需要去配置和运行我们的插件了

### 四、自定义插件的配置与运行

我们需要在Mybatis配置文件里面配置我们的插件。配置时需要注意plugins元素的配置顺序，如果配错了顺序系统就会报错。

```java
<plugins>
		<plugin interceptor="com.itcast.PagingPlugin">
			<property name="dbType" value="mysql"/>
		</plugin>
</plugins>
```

编写sql时指定parameterType为PageParams或其子类，即可使用我们编写的分页插件了。

### 五、总结

综上，我们知道，如果需要在mybatis中自定义插件，需要如下步骤：

1、编写类实现Interceptor接口，重写里面的方法

- intercept(Invocation invocation) ： 核心方法，传入一个Invocation对象，通过它就可以反射调用原来对象的方法
- Object plugin(Object target)：传入的target参数就是被拦截的对象。它的作用是给被拦截的对象生成一个代理对象，并返回
- setProperties(Properties properties)：允许在配置插件时的plugin元素中配置所需要的参数

2、在实现类上使用@Intercepts和@Signature注解来确定插件需要拦截的对象、方法和参数

3、使用插件，在mybatis的核心配置文件SqlMapperConfig.xml文件中配置编写的插件

插件拦截的对象可以是Mybatis的四大运行对象**Executor**、**ParameterHandler**、**StatementHandler**和**ResultHandler**，这样我们就可以在mybatis核心代码运行前去执行一些特殊的要求以满足特殊的场景需求。比如我们上面实现的分页插件，就是拦截的StatementHandler对象，该对象是负责调用JDBC底层的statement或prepareStatement对象来执行SQL，在该对象方法执行前，获取SQL语句，修改成分页SQL语句，从而实现分页效果。



# Mybatis源码分析(跟装X)

![](img\Mybatis层次结构.png)

- **SqlSession** 作为MyBatis工作的主要顶层API，表示和数据库交互的会话，完成必要数据库增删改查功能
- **Executor** MyBatis执行器，是MyBatis 调度的核心，负责SQL语句的生成和查询缓存的维护
- **StatementHandler** 封装了JDBC Statement操作，负责对JDBCstatement的操作，如设置参数、将Statement结果集转换成List集合。
- **ParameterHandler** 负责对用户传递的参数转换成JDBC Statement 所需要的参数
- **ResultSetHandler** 负责将JDBC返回的ResultSet结果集进行封装
- **TypeHandler** 负责java数据类型和jdbc数据类型之间的映射和转换
- **MappedStatement**   它保存映射器的一个节点（select|insert|delete|update），包括配置的SQL，SQL的id、缓存信息、resultMap、parameterType、resultType等重要配置内容
- **SqlSource** 负责根据用户传递的parameterObject，动态地生成SQL语句，将信息封装到BoundSql对象中，并返回
- **BoundSql** 表示动态生成的SQL语句以及相应的参数信息
- **Configuration** MyBatis所有的配置信息都维持在Configuration对象之中



## 1、SqlSessionFactory 对象的创建

```java
    public SqlSessionFactory build(Configuration config) {
        return new DefaultSqlSessionFactory(config);
    }
```

##  2、SqlSession的构建

```java
 private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
        Transaction tx = null;

        DefaultSqlSession var8;
        try {
      //通过Confuguration对象去获取Mybatis相关配置信息, Environment对象包含了数据源和事务的配置
            Environment environment = this.configuration.getEnvironment();
            TransactionFactory transactionFactory = this.getTransactionFactoryFromEnvironment(environment);
            tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
            //之前说了，从表面上来看，咱们是用sqlSession在执行sql语句， 实际呢，其实是通过excutor执行， excutor是对于Statement的封装
            Executor executor = this.configuration.newExecutor(tx, execType);
            //关键看这儿，创建了一个DefaultSqlSession对象
            var8 = new DefaultSqlSession(this.configuration, executor, autoCommit);
        } catch (Exception var12) {
            this.closeTransaction(tx);
            throw ExceptionFactory.wrapException("Error opening session.  Cause: " + var12, var12);
        } finally {
            ErrorContext.instance().reset();
        }

        return var8;
    }
```

## 3、dao接口代理的创建

![](img\MapperProxy.png)

在mybatis中，通过MapperProxy动态代理咱们的dao， 也就是说， 当咱们执行自己写的dao里面的方法的时候，其实是对应的mapperProxy在代理。那么，咱们就看看怎么获取MapperProxy对象吧：

（1）通过SqlSession从Configuration中获取。源码如下：

```java
 	//什么都不做，直接去configuration中找， 哥就是这么任性
	public <T> T getMapper(Class<T> type) {
        return this.configuration.getMapper(type, this);
    }
```

（2）SqlSession把包袱甩给了Configuration, 接下来就看看Configuration。源码如下：

```jvaa
  public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
    return mapperRegistry.getMapper(type, sqlSession);
  }
```

（3）Configuration不要这烫手的山芋，接着甩给了MapperRegistry， 那咱看看MapperRegistry。 源码如下：

```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
        MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory)this.knownMappers.get(type);
        if (mapperProxyFactory == null) {
            throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
        } else {
            try {
                return mapperProxyFactory.newInstance(sqlSession);//关键点
            } catch (Exception var5) {
                throw new BindingException("Error getting mapper instance. Cause: " + var5, var5);
            }
        }
    }
```

(4)MapperProxyFactory是个苦B的人，粗活最终交给它去做了。咱们看看源码：

```java
/**
   * 别人虐我千百遍，我待别人如初恋
   * @param mapperProxy
   * @return
   */
  @SuppressWarnings("unchecked")
  protected T newInstance(MapperProxy<T> mapperProxy) {
    //动态代理我们写的dao接口
    return (T) Proxy.newProxyInstance(mapperInterface.getClassLoader(), new Class[] { mapperInterface }, mapperProxy);
  }
  
  public T newInstance(SqlSession sqlSession) {
    final MapperProxy<T> mapperProxy = new MapperProxy<T>(sqlSession, mapperInterface, methodCache);
    return newInstance(mapperProxy);
  }
```

## 4、sql执行

![](img\sql执行.png)

MapperProxy:

```java
/**
   * MapperProxy在执行时会触发此方法
   */
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
   try {
        if (Object.class.equals(method.getDeclaringClass())) {
        	return method.invoke(this, args);
       	}

      	if (this.isDefaultMethod(method)) {
          return this.invokeDefaultMethod(proxy, method, args);
      	}
      } catch (Throwable var5) {
            throw ExceptionUtil.unwrapThrowable(var5);
      }
	//二话不说，主要交给MapperMethod自己去管
       MapperMethod mapperMethod = this.cachedMapperMethod(method);
       return mapperMethod.execute(this.sqlSession, args);
   }
```

MapperMethod:

```java
/**
   * 看着代码不少，不过其实就是先判断CRUD类型，然后根据类型去选择到底执行sqlSession中的哪个方法，绕了一圈，又转回sqlSession了
   * @param sqlSession
   * @param args
   * @return
   */
public Object execute(SqlSession sqlSession, Object[] args) {
        Object param;
        Object result;
        switch(this.command.getType()) {
        case INSERT:
            param = this.method.convertArgsToSqlCommandParam(args);
            result = this.rowCountResult(sqlSession.insert(this.command.getName(), param));
            break;
        case UPDATE:
            param = this.method.convertArgsToSqlCommandParam(args);
            result = this.rowCountResult(sqlSession.update(this.command.getName(), param));
            break;
        case DELETE:
            param = this.method.convertArgsToSqlCommandParam(args);
            result = this.rowCountResult(sqlSession.delete(this.command.getName(), param));
            break;
        case SELECT:
            if (this.method.returnsVoid() && this.method.hasResultHandler()) {
                this.executeWithResultHandler(sqlSession, args);
                result = null;
            } else if (this.method.returnsMany()) {
                result = this.executeForMany(sqlSession, args);
            } else if (this.method.returnsMap()) {
                result = this.executeForMap(sqlSession, args);
            } else if (this.method.returnsCursor()) {
                result = this.executeForCursor(sqlSession, args);
            } else {
                param = this.method.convertArgsToSqlCommandParam(args);
                result = sqlSession.selectOne(this.command.getName(), param);
            }
            break;
        case FLUSH:
            result = sqlSession.flushStatements();
            break;
        default:
            throw new BindingException("Unknown execution method for: " + this.command.getName());
        }

        if (result == null && this.method.getReturnType().isPrimitive() && !this.method.returnsVoid()) {
            throw new BindingException("Mapper method '" + this.command.getName() + " attempted to return null from a method with a primitive return type (" + this.method.getReturnType() + ").");
        } else {
            return result;
        }
    }
```

既然又回到SqlSession了， 那么咱们就看看SqlSession的CRUD方法了，为了省事，还是就选择其中的一个方法来做分析吧。这儿，咱们选择了selectList方法：

```java
public <E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds) {
        List var5;
        try {
            MappedStatement ms = this.configuration.getMappedStatement(statement);
            //CRUD实际上是交给Excetor去处理， excutor其实也只是穿了个马甲而已，小样，别以为穿个马甲我就不认识你嘞！
            var5 = this.executor.query(ms, this.wrapCollection(parameter), rowBounds, Executor.NO_RESULT_HANDLER);
        } catch (Exception var9) {
            throw ExceptionFactory.wrapException("Error querying database.  Cause: " + var9, var9);
        } finally {
            ErrorContext.instance().reset();
        }

        return var5;
    }
```

然后，通过一层一层的调用，最终会来到doQuery方法， 这儿咱们就随便找个**Excutor**看看doQuery方法的实现吧，我这儿选择了SimpleExecutor:

```java
    public <E> List<E> doQuery(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) throws SQLException {
        Statement stmt = null;
        List var9;
        try {
            Configuration configuration = ms.getConfiguration();
            StatementHandler handler = configuration.newStatementHandler(this.wrapper, ms, parameter, rowBounds, resultHandler, boundSql);
            stmt = this.prepareStatement(handler, ms.getStatementLog());
             //StatementHandler封装了Statement, 让 StatementHandler 去处理
            var9 = handler.query(stmt, resultHandler);
        } finally {
            this.closeStatement(stmt);
        }

        return var9;
    }

    private Statement prepareStatement(StatementHandler handler, Log statementLog) throws SQLException {
        Connection connection = this.getConnection(statementLog);
        Statement stmt = handler.prepare(connection, this.transaction.getTimeout());
       	//参数封装
        handler.parameterize(stmt);
        return stmt;
    }
```

接下来，咱妈看看ParameterHandler的一个实现类**DefaultParameterHandler**，看看它是如何封装参数的：

```java
public void setParameters(PreparedStatement ps) {
        ErrorContext.instance().activity("setting parameters").object(this.mappedStatement.getParameterMap().getId());
        List<ParameterMapping> parameterMappings = this.boundSql.getParameterMappings();
        if (parameterMappings != null) {
            for(int i = 0; i < parameterMappings.size(); ++i) {
                ParameterMapping parameterMapping = (ParameterMapping)parameterMappings.get(i);
                if (parameterMapping.getMode() != ParameterMode.OUT) {
                    String propertyName = parameterMapping.getProperty();
                    Object value;
                    if (this.boundSql.hasAdditionalParameter(propertyName)) {
                        value = this.boundSql.getAdditionalParameter(propertyName);
                    } else if (this.parameterObject == null) {
                        value = null;
                    } else if (this.typeHandlerRegistry.hasTypeHandler(this.parameterObject.getClass())) {
                        value = this.parameterObject;
                    } else {
                        MetaObject metaObject = this.configuration.newMetaObject(this.parameterObject);
                        value = metaObject.getValue(propertyName);
                    }

                    TypeHandler typeHandler = parameterMapping.getTypeHandler();
                    JdbcType jdbcType = parameterMapping.getJdbcType();
                    if (value == null && jdbcType == null) {
                        jdbcType = this.configuration.getJdbcTypeForNull();
                    }

                    try {
                        typeHandler.setParameter(ps, i + 1, value, jdbcType);
                    } catch (TypeException var10) {
                        throw new TypeException("Could not set parameters for mapping: " + parameterMapping + ". Cause: " + var10, var10);
                    } catch (SQLException var11) {
                        throw new TypeException("Could not set parameters for mapping: " + parameterMapping + ". Cause: " + var11, var11);
                    }
                }
            }
        }

    }
```



接下来，咱们看看StatementHandler 的一个实现类 **PreparedStatementHandler**（这也是我们最常用的，封装的是PreparedStatement）, 看看它使怎么去处理的：

```java

	public <E> List<E> query(Statement statement, ResultHandler resultHandler) throws SQLException {
         //到此，原形毕露， PreparedStatement, 这个大家都已经滚瓜烂熟了吧
        PreparedStatement ps = (PreparedStatement)statement;
        ps.execute();
         //结果交给了ResultSetHandler 去处理
        return this.resultSetHandler.handleResultSets(ps);
    }
```

最后我们看看结果是如何封装并返回的，DefaultResultSetHandler默认的结果集处理类

```java
public List<Object> handleResultSets(Statement stmt) throws SQLException {
        ErrorContext.instance().activity("handling results").object(this.mappedStatement.getId());
        List<Object> multipleResults = new ArrayList();
        int resultSetCount = 0;
        ResultSetWrapper rsw = this.getFirstResultSet(stmt);
        List<ResultMap> resultMaps = this.mappedStatement.getResultMaps();
        int resultMapCount = resultMaps.size();
        this.validateResultMapsCount(rsw, resultMapCount);

        while(rsw != null && resultMapCount > resultSetCount) {
            ResultMap resultMap = (ResultMap)resultMaps.get(resultSetCount);
            this.handleResultSet(rsw, resultMap, multipleResults, (ResultMapping)null);
            rsw = this.getNextResultSet(stmt);
            this.cleanUpAfterHandlingResultSet();
            ++resultSetCount;
        }

        String[] resultSets = this.mappedStatement.getResultSets();
        if (resultSets != null) {
            while(rsw != null && resultSetCount < resultSets.length) {
                ResultMapping parentMapping = (ResultMapping)this.nextResultMaps.get(resultSets[resultSetCount]);
                if (parentMapping != null) {
                    String nestedResultMapId = parentMapping.getNestedResultMapId();
                    ResultMap resultMap = this.configuration.getResultMap(nestedResultMapId);
                    this.handleResultSet(rsw, resultMap, (List)null, parentMapping);
                }

                rsw = this.getNextResultSet(stmt);
                this.cleanUpAfterHandlingResultSet();
                ++resultSetCount;
            }
        }

        return this.collapseSingleResultList(multipleResults);
    }
```

