​	

<center><font size=50>JAVA安全框架简介</font></center>

[TOC]



# 第一章	SpringSecurity功能介绍和原理分析

## 一、基本原理

![](springSecurity原理1.png)

```xml
绿色部分的各个过滤器(如UsernamePasswordAuthenticationFilter)，主要完成SpringSecurity的各种认证工作，如Form表单认证和http basic认证等
黄色的FilterSecurityInterceptor是整个过滤器链中的最后一环，最终由它决定当前请求能否到达最后请求的资源
蓝色的ExceptionTranslationFilter过滤器，用于捕获FilterSecurityInterceptor抛出的各种异常，进行对应的处理
```



## 二、用户信息获取

```java
/**
 * 获取用户信息的核心接口
 */
public interface UserDetailsService {

	/**
	 * 根据用户名查询用户信息，封装在一个UserDetails接口中
	 */
	UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

User类，UserDetails接口的实现类，用于封装用户信息的。

```java
public class User implements UserDetails, CredentialsContainer {
	private String password;
	private final String username;
	private final Set<GrantedAuthority> authorities;//用户角色集合
	private final boolean accountNonExpired;//账户是否过期
	private final boolean accountNonLocked;//账户是否冻结
	private final boolean credentialsNonExpired;//密码是否过期
	private final boolean enabled;//账户是否失效
	}
```

```xml
	<!-- 在认证管理器中指定使用 UserDetailsService-->
	<authentication-manager>
		<authentication-provider user-service-ref="">
			
		</authentication-provider>	
	</authentication-manager>
```



## 三、密码加密解密

```java
/**
 *SpringSecurity提供该接口用于密码的加密和校验
 */
public interface PasswordEncoder {
	/**
	 * 密码加密
	 */
	String encode(CharSequence rawPassword);

	/**
	 * 密码校验
	 */
	boolean matches(CharSequence rawPassword, String encodedPassword);
}
```

SpringSecurity提供的密码加密解密类用如下：

![](passwordEncoder.png)

```xml
<!--认证管理器 -->
	<authentication-manager>
        <!--在认证提供者中配置密码加密解密类-->
		<authentication-provider user-service-ref="userDetailService">	
			<password-encoder ref="bcryptEncoder"></password-encoder>
		</authentication-provider>	
	</authentication-manager>
<!--创建密码加密解密类 -->
	<beans:bean id="bcryptEncoder" class="org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder"></beans:bean>

```

## 四、个性化用户认证流程

### 1、处理登录成功

接口及常用实现类

```java
AuthenticationSuccessHandler
--SavedRequestAwareAuthenticationSuccessHandler
--ForwardAuthenticationSuccessHandler
--SimpleUrlAuthenticationSuccessHandler
```

自定义认证成功处理器

```java
public class AuthenticationSuccessHandler extends SavedRequestAwareAuthenticationSuccessHandler {
	private String type;

	@Override
	public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
			Authentication authentication) throws IOException, ServletException {
		logger.info("登录成功");
		if ("json".equalsIgnoreCase(this.type) || "json".equalsIgnoreCase(request.getParameter("type"))) {
			response.setContentType("application/json;charset=UTF-8");
			response.getWriter().write("{\"name\":\""+authentication.getName()+"\"}");
		} else {
			super.onAuthenticationSuccess(request, response, authentication);
		}

	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}

}
```

配置

```xml
<form-login   
		login-page="/login.jsp" 
		default-target-url="/index.html" 
		authentication-failure-url="/login.jsp"
		authentication-success-handler-ref="authenticationSuccessHandler"/>
```



### 2、处理登录失败

接口及常用实现类

```
AuthenticationFailureHandler
--SimpleUrlAuthenticationFailureHandler
--DelegatingAuthenticationFailureHandler
--ForwardAuthenticationFailureHandler
```

自定义认证失败处理器

```java
public class AuthenctiationFailureHandler extends SimpleUrlAuthenticationFailureHandler {
	private String type;
    
	@Override
	public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response,
			AuthenticationException exception) throws IOException, ServletException {
		
		logger.info("登录失败");
		
		if ("json".equalsIgnoreCase(this.type)|| "json".equalsIgnoreCase(request.getParameter("type"))) {
			response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR.value());
			response.setContentType("application/json;charset=UTF-8");
			response.getWriter().write("{\"message\":\""+exception.getMessage()+"\"}");
		}else{
			request.setAttribute("error", exception.getMessage());
			super.setDefaultFailureUrl("/login.jsp");
			super.setUseForward(true);
			super.onAuthenticationFailure(request, response, exception);
		}
	}
    
	public String getType() {
		return type;
	}
    
	public void setType(String type) {
		this.type = type;
	}
}
```

配置

```xml
<form-login   
		login-page="/login.jsp" 
		default-target-url="/index.html" 
		authentication-failure-url="/login.jsp"
		authentication-failure-handler-ref="authenctiationFailureHandler"/>
```



## 五、认证流程详解



![](认证01.png)



认证成功后认证结果在多个请求之间实现共享

![](认证02.png)

SecurityContextPersistenceFilter实现认证结果共享

![](认证04.png)



## 六、实现图形验证码功能

### 1、编写生成验证码图片的接口

```java
public class ImageCode {
	private BufferedImage image; 
	private String code;
	private LocalDateTime expireTime;
	
	public ImageCode(BufferedImage image, String code, int expireIn){
		this.image = image;
		this.setCode(code);
		this.setExpireTime(LocalDateTime.now().plusSeconds(expireIn));
	}
	
	public ImageCode(BufferedImage image, String code, LocalDateTime expireTime){
		this.image = image;
		this.setCode(code);
		this.setExpireTime(expireTime);
	}
	
	public BufferedImage getImage() {
		return image;
	}

	public void setImage(BufferedImage image) {
		this.image = image;
	}

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}

	public LocalDateTime getExpireTime() {
		return expireTime;
	}

	public void setExpireTime(LocalDateTime expireTime) {
		this.expireTime = expireTime;
	}
	
	public boolean isExpried() {
		return LocalDateTime.now().isAfter(expireTime);
	}
}
```

```java
//生成图片接口
@RestController
public class ValidateCodeController {

	public static final String SESSION_KEY = "SESSION_KEY_IMAGE_CODE";
	
	@RequestMapping("/code/image")
	public void createCode(HttpServletRequest request,HttpServletResponse response) throws IOException{
		ImageCode imageCode = createImageCode(request);
		request.getSession().setAttribute(SESSION_KEY, imageCode);
		ImageIO.write(imageCode.getImage(), "JPEG", response.getOutputStream());
		
	}

	private ImageCode createImageCode(HttpServletRequest request) {
		int width =67;
		int height = 23;
		BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);

		Graphics g = image.getGraphics();

		Random random = new Random();

		g.setColor(getRandColor(200, 250));
		g.fillRect(0, 0, width, height);
		g.setFont(new Font("Times New Roman", Font.ITALIC, 20));
		g.setColor(getRandColor(160, 200));
		for (int i = 0; i < 155; i++) {
			int x = random.nextInt(width);
			int y = random.nextInt(height);
			int xl = random.nextInt(12);
			int yl = random.nextInt(12);
			g.drawLine(x, y, x + xl, y + yl);
		}

		String sRand = "";
		for (int i = 0; i < 4; i++) {
			String rand = String.valueOf(random.nextInt(10));
			sRand += rand;
			g.setColor(new Color(20 + random.nextInt(110), 20 + random.nextInt(110), 20 + random.nextInt(110)));
			g.drawString(rand, 13 * i + 6, 16);
		}

		g.dispose();

		return new ImageCode(image, sRand, 60);
	}
	
	/**
	 * 生成随机背景条纹
	 */
	private Color getRandColor(int fc, int bc) {
		Random random = new Random();
		if (fc > 255) {
			fc = 255;
		}
		if (bc > 255) {
			bc = 255;
		}
		int r = fc + random.nextInt(bc - fc);
		int g = fc + random.nextInt(bc - fc);
		int b = fc + random.nextInt(bc - fc);
		return new Color(r, g, b);
	}

}
```

### 2、编写自定义的过滤器，完成验证码校验

```java
public class ValidateCodeFilter extends OncePerRequestFilter{
	@Autowired
	private AuthenticationFailureHandler authenticationFailureHandler;
	
	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {
		if("/login".equals(request.getRequestURI())&&
				"post".equalsIgnoreCase(request.getMethod())){
			try {
				validate(new ServletWebRequest(request));
			} catch (ValidateCodeException exception) {
				authenticationFailureHandler.onAuthenticationFailure(request, response, exception);
			}
		}
		filterChain.doFilter(request, response);
		
	}

	private void validate(ServletWebRequest request) throws ServletRequestBindingException, ValidateCodeException {
		ImageCode codeInSession = (ImageCode) request.getRequest().getSession().getAttribute(ValidateCodeController.SESSION_KEY);
		String codeInRequest = ServletRequestUtils.getStringParameter(request.getRequest(), "imageCode");
		
		if(StringUtils.isEmpty(codeInRequest)){
			throw new ValidateCodeException("验证码的值不能为空");
		}
		
		if(codeInSession==null){
			throw new ValidateCodeException("验证码不存在");
		}
		
		if (codeInSession.isExpried()) {
			request.getRequest().getSession().removeAttribute( ValidateCodeController.SESSION_KEY);
			throw new ValidateCodeException( "验证码已过期");
		}

		if (!codeInRequest.equals(codeInSession.getCode())) {
			throw new ValidateCodeException( "验证码不匹配");
		}

		request.getRequest().getSession().removeAttribute( ValidateCodeController.SESSION_KEY);
	}

}
```

```java
//验证码校验失败异常类
public class ValidateCodeException extends AuthenticationException {
	private static final long serialVersionUID = 1L;
	public ValidateCodeException(String explanation) {
		super(explanation);
	}
}
```

### 3、在spring Security中配置过滤器

```xml
<http use-expressions="false">
	<!-- 当前用户必须有ROLE_USER的角色 才可以访问根目录及所属子目录的资源 -->
	<intercept-url pattern="/**" access="ROLE_USER"/>
	<!-- 开启表单登陆功能 -->
	<form-login   
		login-page="/login.jsp" 
		default-target-url="/index.html" 
		authentication-failure-url="/login.jsp"/>
		<csrf disabled="true"/>
		<logout />
	<custom-filter ref="validateCodeFilter" before="FORM_LOGIN_FILTER"/>
</http>
```

## 七、实现记住我功能

Spring Security提供了remember-me标签，可以实现自动登录的功能。Remember-me 使用在 UsernamePasswordAuthenticationFilter 中，通过在它的超类AbstractAuthenticationProcessingFilter 里实现的一个调用钩子。这个钩子会在合适的时候调用一个具体的 RememberMeServices

```xml
<remember-me />
<!--
属性：
	remember-me-parameter	传递给后台的请求参数名，用于触发remember-me自动登录功能。默认值是"remember-me"
	remember-me-cookie	存储自动登录token的cookie名，默认是"remember-me"
	key	设置用来防止修改 token 的key，不设置将采用随机值
	services-ref	指定自定义的RememberMeServices 
	use-secure-cookie	使用安全的cookie(只能在HTTPS下被发送)
	user-service-ref		指定UserDetailsService
	token-validity-seconds		设置token的有效期，默认是14days
	data-source-ref	设置一个数据源，如果设置将会使用PersistentTokenBasedRememberMeServices 
	JdbcTokenRepositoryImpl
-->
```

原理解析

![](remember-me.jpg)



## 八、实现短信登录

### 1、编写发送短信的接口

```java
public class SmsCodeController {

	public static final String SESSION_KEY = "SESSION_KEY_SMS_CODE";
	
	@RequestMapping("/code/sms")
	public void createCode(HttpServletRequest request,HttpServletResponse response,String phoneNum) throws IOException{
		String smsCode = createImageCode(phoneNum);
		request.getSession().setAttribute(SESSION_KEY, smsCode);
        System.out.println(smsCode);
	}

	private String createImageCode(String phoneNum) {
        long random = (long)(Math.random()*1000000);
        return random+"";
	}
}
```

### 2、实现短信登录

![](短信登录.png)

#### 2.1、编写SmsAuthenticationToken类

我们可以模仿UsernamePasswordAuthticationToken来编写！！

```java
public class SmsAuthenticationToken extends AbstractAuthenticationToken {
    private static final long serialVersionUID = SpringSecurityCoreVersion.SERIAL_VERSION_UID;

    private final Object principal;
    public SmsAuthenticationToken(Object principal) {
        super(null);
        this.principal = principal;
        setAuthenticated(false);
    }

    public SmsAuthenticationToken(Object principal,
                                               Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.principal = principal;
        super.setAuthenticated(true); // must use super, as we override
    }

    public Object getCredentials() {
        return null;
    }

    public Object getPrincipal() {
        return this.principal;
    }

    public void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException {
        if (isAuthenticated) {
            throw new IllegalArgumentException(
                    "Cannot set this token to trusted - use constructor which takes a GrantedAuthority list instead");
        }

        super.setAuthenticated(false);
    }

    @Override
    public void eraseCredentials() {
        super.eraseCredentials();
    }
}
```

#### 2.2、编写SmsAuthenticationFilter类

拦截短信登录请求，该类的编写我们可以参考UsernamePasswordAuthenticationFilter类

```java
public class SmsAuthenticationFilter extends
        AbstractAuthenticationProcessingFilter {
    public static final String SPRING_SECURITY_FORM_SMECODE_KEY = "smsCode";
    private String smscodeParameter = SPRING_SECURITY_FORM_SMECODE_KEY;
    private boolean postOnly = true;

    public SmsAuthenticationFilter() {
        super(new AntPathRequestMatcher("/mobile", "POST"));
    }

    public Authentication attemptAuthentication(HttpServletRequest request,
        HttpServletResponse response) throws AuthenticationException {
        if (postOnly && !request.getMethod().equals("POST")) {
            throw new AuthenticationServiceException(
                    "Authentication method not supported: " + request.getMethod());
        }

        String smscode = obtainSmscode(request);
        if (smscode == null) {
            smscode = "";
        }

        smscode = smscode.trim();
        SmsAuthenticationToken authRequest = new SmsAuthenticationToken(
                smscode);

        // Allow subclasses to set the "details" property
        setDetails(request, authRequest);
        return this.getAuthenticationManager().authenticate(authRequest);
    }

    protected String obtainSmscode(HttpServletRequest request) {
        return request.getParameter(smscodeParameter);
    }

    protected void setDetails(HttpServletRequest request,
                              SmsAuthenticationToken authRequest) {
        authRequest.setDetails(authenticationDetailsSource.buildDetails(request));
    }

    public void setUsernameParameter(String smscodeParameter) {
        Assert.hasText(smscodeParameter, "Username parameter must not be empty or null");
        this.smscodeParameter = smscodeParameter;
    }

    public void setPostOnly(boolean postOnly) {
        this.postOnly = postOnly;
    }

    public final String getSmscodeParameter() {
        return smscodeParameter;
    }
}
```

#### 2.3、编写校验逻辑类SmsAuthenticationProvider

```java
public class SmsAuthenticationProvider implements AuthenticationProvider {

    private UserDetailsService userDetailsService;

    public UserDetailsService getUserDetailsService() {
        return userDetailsService;
    }

    public void setUserDetailsService(UserDetailsService userDetailsService) {
        this.userDetailsService = userDetailsService;
    }

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        SmsAuthenticationToken smsAuthenticationToken = (SmsAuthenticationToken)authentication;
        UserDetails userDetails = userDetailsService.loadUserByUsername((String) smsAuthenticationToken.getPrincipal());

        if(userDetails == null){
            throw new InternalAuthenticationServiceException("无法获取用户信息");
        }
        SmsAuthenticationToken authenticationToken = new SmsAuthenticationToken(userDetails,userDetails.getAuthorities());
        authenticationToken.setDetails(smsAuthenticationToken.getDetails());
        return authenticationToken;
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return SmsAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

#### 2.4、编写短信验证过滤器ValidateSmsCodeFilter类

```java
public class ValidateSmsCodeFilter extends OncePerRequestFilter{
	@Autowired
	private AuthenticationFailureHandler authenticationFailureHandler;
	
	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {
		if("/mobile".equals(request.getRequestURI())&&
				"post".equalsIgnoreCase(request.getMethod())){
			try {
				validate(new ServletWebRequest(request));
			} catch (ValidateCodeException exception) {
				authenticationFailureHandler.onAuthenticationFailure(request, response, exception);
			}
		}
		filterChain.doFilter(request, response);
		
	}

	private void validate(ServletWebRequest request) throws ServletRequestBindingException, ValidateCodeException {
		String codeInSession = (String) request.getRequest().getSession().getAttribute(SmsCodeController.SESSION_KEY);
		String codeInRequest = ServletRequestUtils.getStringParameter(request.getRequest(), "smsCode");
		
		if(StringUtils.isEmpty(codeInRequest)){
			throw new ValidateCodeException("验证码的值不能为空");
		}
		
		if(codeInSession==null){
			throw new ValidateCodeException("验证码不存在");
		}

		if (!codeInRequest.equals(codeInSession)) {
			throw new ValidateCodeException( "验证码不匹配");
		}

		request.getRequest().getSession().removeAttribute( SmsCodeController.SESSION_KEY);
	}

}
```

### 3、配置

```xml
<http use-expressions="false" >
		<!-- 当前用户必须有ROLE_USER的角色 才可以访问根目录及所属子目录的资源 -->
		<intercept-url pattern="/**" access="ROLE_USER"/>
		<!-- 开启表单登陆功能 -->
		<form-login   
		login-page="/login.jsp" 
		default-target-url="/index.html" 
		authentication-failure-url="/login.jsp"
		authentication-success-handler-ref="authenticationSuccessHandler"
		authentication-failure-handler-ref="authenctiationFailureHandler"/>
		<csrf disabled="true"/>
		<logout />		
		<!--配置短信验证码校验过滤器-->
		<custom-filter ref="validateSmsCodeFilter" before="FORM_LOGIN_FILTER"/>
    	<!--配置短信认证过滤器-->
		<custom-filter ref="smsAuthenticationFilter" after="FORM_LOGIN_FILTER"/>
		<remember-me services-alias="rememberMe"  />
	</http>
	<!--配置短信认证过滤器类bean-->
	<beans:bean id="smsAuthenticationFilter" class="com.itcast.filter.SmsAuthenticationFilter">
		<beans:property name="authenticationManager" ref="authenticationManager"></beans:property>
		<beans:property name="rememberMeServices" ref="rememberMe"></beans:property>
	</beans:bean>
	
	<!-- 认证管理器 -->
	<authentication-manager id="authenticationManager">
		<authentication-provider user-service-ref="userDetailsService" >
		</authentication-provider>
        
		<!-- 短信登录认证提供者-->
		<authentication-provider ref="smsAuthenticationProvider" >
		</authentication-provider>
	</authentication-manager>
```

## 九、Session管理

spring security提供了**session-management**标签，可以实现会话管理的功能。HTTP 会 话 相 关 的 功 能 是 由 SessionManagementFilter 和SessionAuthenticationStrategy 接口联合处理的， 过滤器会代理它们。 典型的应用包括会话伪造攻击预防，检测会话超时， 限制已登录用户可以同时打开多少会话。

```xml
<!-- 添加一个默认的SessionManagementFilter 到我们的过滤器链中来实现session的管理 -->
<session-management>
	<concurrency-control max-sessions="1" error-if-maximum-exceeded="true"/>
</session-management>
<!--
属性：
	invalid-session-url		当提交一个无效的sessionId时会重定向到一个指定的URL
	session-authentication-strategy-ref	指定一个session认证策略SessionAuthenticationStrategy 
	session-authentication-error-url		指定当session认证发生异常时，跳转的页面。默认返回401未授权错误码。
	session-fixation-protection		当用户认证时指定会话固定保护。none、newSession、migrateSession、changeSessionId

子元素
<concurrency-control>  ConcurrentSessionControlStrategy
	会话并发控制，允许用户的当前活跃会话数。
	max-sessions	最大会话数。-1表示不限制
	session-registry-ref	指定SessionRegistry实现

	error-if-maximum-exceeded 	If set to "true" a SessionAuthenticationException will be raised when a user attempts to exceed the maximum allowed number of sessions. The default behaviour is to expire the original session.

	expired-url 	The URL a user will be redirected to if they attempt to use a session which has been "expired" by the concurrent session controller because the user has exceeded the number of allowed sessions and has logged in again elsewhere. Should be set unless exception-if-maximum-exceeded is set. If no value is supplied, an expiry message will just be written directly back to the response.
-->
```

需要在web.xml文件中添加如下配置

```xml
<listener>
		<listener-class>org.springframework.security.web.session.HttpSessionEventPublisher</listener-class>
</listener>
```



## 十、授权

### 10.1、Spring Security授权流程解析

![](授权流程.png)



#### 10.1.1、服务请求到达FilterSecurityInterceptor拦截器拦截，执行invoke方法

```java
public void invoke(FilterInvocation fi) throws IOException, ServletException {
		if ((fi.getRequest() != null)
				&& (fi.getRequest().getAttribute(FILTER_APPLIED) != null)
				&& observeOncePerRequest) {
			// filter already applied to this request and user wants us to observe
			// once-per-request handling, so don't re-do security checking
			fi.getChain().doFilter(fi.getRequest(), fi.getResponse());
		}
		else {
			// first time this request being called, so perform security checking
			if (fi.getRequest() != null) {
				fi.getRequest().setAttribute(FILTER_APPLIED, Boolean.TRUE);
			}
            //到达请求资源前，绝对是否有权访问
			InterceptorStatusToken token = super.beforeInvocation(fi);

			try {
                //访问请求资源
				fi.getChain().doFilter(fi.getRequest(), fi.getResponse());
			}
			finally {
				super.finallyInvocation(token);
			}
			super.afterInvocation(token, null);
		}
	}
```

#### 10.1.2、调用父类AbstractSecurityInterceptor的beforeInvocation决定是否授权访问

```java
protected InterceptorStatusToken beforeInvocation(Object object) {
    //获取当前请求资源的可访问权限列表
	Collection<ConfigAttribute> attributes = this.obtainSecurityMetadataSource()
				.getAttributes(object);
    //获取当前认证信息
	Authentication authenticated = authenticateIfRequired();

	// 开始授权
	try {
		this.accessDecisionManager.decide(authenticated, object, attributes);
	}
	catch (AccessDeniedException accessDeniedException) {
        //权限不足，无法访问！！
		publishEvent(new AuthorizationFailureEvent(object, attributes, authenticated,
				accessDeniedException));
		throw accessDeniedException;
	}

	// Attempt to run as a different user
	Authentication runAs = this.runAsManager.buildRunAs(authenticated, object,
				attributes);

	if (runAs == null) {
        ......
		return new InterceptorStatusToken(SecurityContextHolder.getContext(), false,
				attributes, object);
	}
}
```

#### 10.1.3、调用授权管理器AccessDecisionManager接口的decide方法做出最后的访问控制决策

```java
public interface AccessDecisionManager {
	/**
	 * Resolves an access control decision for the passed parameters.
	 *
	 * @param authentication the caller invoking the method (not null)
	 * @param object the secured object being called
	 * @param configAttributes the configuration attributes associated with the secured
	 * object being invoked
	 *
	 * @throws AccessDeniedException if access is denied as the authentication does not
	 * hold a required authority or ACL privilege
	 * @throws InsufficientAuthenticationException if access is denied as the
	 * authentication does not provide a sufficient level of trust
	 */
	void decide(Authentication authentication, Object object,
			Collection<ConfigAttribute> configAttributes) throws AccessDeniedException,
			InsufficientAuthenticationException;

	/**
	 * Indicates whether this <code>AccessDecisionManager</code> is able to process
	 * authorization requests presented with the passed <code>ConfigAttribute</code>.
	 * <p>
	 * This allows the <code>AbstractSecurityInterceptor</code> to check every
	 * configuration attribute can be consumed by the configured
	 * <code>AccessDecisionManager</code> and/or <code>RunAsManager</code> and/or
	 * <code>AfterInvocationManager</code>.
	 * </p>
	 *
	 * @param attribute a configuration attribute that has been configured against the
	 * <code>AbstractSecurityInterceptor</code>
	 *
	 * @return true if this <code>AccessDecisionManager</code> can support the passed
	 * configuration attribute
	 */
	boolean supports(ConfigAttribute attribute);

	/**
	 * Indicates whether the <code>AccessDecisionManager</code> implementation is able to
	 * provide access control decisions for the indicated secured object type.
	 *
	 * @param clazz the class that is being queried
	 *
	 * @return <code>true</code> if the implementation can process the indicated class
	 */
	boolean supports(Class<?> clazz);
}
```

#### 10.1.4、授权管理器接口AccessDecisionManager的实现类

![](授权管理器接口实现类.png)

Spring Security默认提供了AffirmativeBased、ConsensusBased、UnanimousBased三种基于投票机制的AccessDecisionManager接口实现。每一个实现类中都定义了一个**`AccessDecisionVoter`**投票器列表

```java
	private List<AccessDecisionVoter<? extends Object>> decisionVoters;
```

接口`AccessDecisionVoter`的定义如下：

```java
public interface AccessDecisionVoter<S> {

	int ACCESS_GRANTED = 1;//同意
	int ACCESS_ABSTAIN = 0;//弃权
	int ACCESS_DENIED = -1;//拒绝

	/**
	 * Indicates whether this {@code AccessDecisionVoter} is able to vote on the passed
	 * {@code ConfigAttribute}.
	 * <p>
	 * This allows the {@code AbstractSecurityInterceptor} to check every configuration
	 * attribute can be consumed by the configured {@code AccessDecisionManager} and/or
	 * {@code RunAsManager} and/or {@code AfterInvocationManager}.
	 *
	 * @param attribute a configuration attribute that has been configured against the
	 * {@code AbstractSecurityInterceptor}
	 *
	 * @return true if this {@code AccessDecisionVoter} can support the passed
	 * configuration attribute
	 */
	boolean supports(ConfigAttribute attribute);

	/**
	 * Indicates whether the {@code AccessDecisionVoter} implementation is able to provide
	 * access control votes for the indicated secured object type.
	 *
	 * @param clazz the class that is being queried
	 *
	 * @return true if the implementation can process the indicated class
	 */
	boolean supports(Class<?> clazz);

	/**
	 * Indicates whether or not access is granted.
	 * <p>
	 * The decision must be affirmative ({@code ACCESS_GRANTED}), negative (
	 * {@code ACCESS_DENIED}) or the {@code AccessDecisionVoter} can abstain (
	 * {@code ACCESS_ABSTAIN}) from voting. Under no circumstances should implementing
	 * classes return any other value. If a weighting of results is desired, this should
	 * be handled in a custom
	 * {@link org.springframework.security.access.AccessDecisionManager} instead.
	 * <p>
	 * Unless an {@code AccessDecisionVoter} is specifically intended to vote on an access
	 * control decision due to a passed method invocation or configuration attribute
	 * parameter, it must return {@code ACCESS_ABSTAIN}. This prevents the coordinating
	 * {@code AccessDecisionManager} from counting votes from those
	 * {@code AccessDecisionVoter}s without a legitimate interest in the access control
	 * decision.
	 * <p>
	 * Whilst the secured object (such as a {@code MethodInvocation}) is passed as a
	 * parameter to maximise flexibility in making access control decisions, implementing
	 * classes should not modify it or cause the represented invocation to take place (for
	 * example, by calling {@code MethodInvocation.proceed()}).
	 *
	 * @param authentication the caller making the invocation
	 * @param object the secured object being invoked
	 * @param attributes the configuration attributes associated with the secured object
	 *
	 * @return either {@link #ACCESS_GRANTED}, {@link #ACCESS_ABSTAIN} or
	 * {@link #ACCESS_DENIED}
	 */
	int vote(Authentication authentication, S object,
			Collection<ConfigAttribute> attributes);
}
```

在AccessDecisionManager接口的decide方法实现中会循环调用投票器列表中的所有投票器，进行投票表决，最终来决定当前访问是否能够授权通过。

- AffirmativeBased：有一个投通过，则通过
- ConsensusBased：比较投通过和拒绝的票数，谁多算谁的
- UnanimousBased：有一个投拒绝，则拒绝

当然我们也可以自定义AccessDecisionManager实现！！

#### 10.1.5、投票器接口AccessDecisionVoter的实现类

![](投票器接口实现9.png)

##### 	1）、RoleVoter

​	Spring Security 中最常用到的 AccessDecisionVoter 实现是简单的 RoleVoter，它把简单的角色名称作为配置属性，如果用户分配了某个角色就被允许访问。如果有任何一个配置属性是以 ROLE_开头的，就可以进行投票。

##### 	2）、AuthenticatedVoter

​	另外一个实现是`AuthenticatedVoter`，它可以用来区分匿名用户，认证过的用户和remember-me认证的用户。许多站点允许在remember-me身份验证下进行某些有限访问，但需要用户通过登录进行完全访问来确认其身份。 当使用`IS_AUTHENTICATED_ANONYMOUSLY`属性来授予匿名访问权限的时候，`AuthenticatedVoter`会处理此属性

##### 	3）、WebExpressionVoter

​	Spring Security中用于为基于表达式授权的web请求投票的Voter

##### 	4）、PreInvocationAuthorizationAdviceVoter

​	Spring Security中用于为基于方法粒度授权的投票器​	

当然我们也可以自定义AccessDecisionVoter实现！！



### 10.2、Spring Security授权配置

#### 10.2.1、ROLE_*权限控制

```xml
<http use-expressions="false" >
   <!-- 当前用户必须有ROLE_USER的角色 才可以访问根目录及所属子目录的资源 -->
   <intercept-url pattern="/**" access="ROLE_USER" />
</http>
```



#### 10.2.2、基于表达式的权限控制

​	Spring Security允许我们在定义URL访问或方法访问所应有的权限时使用Spring EL表达式，在定义所需的访问权限时如果对应的表达式返回结果为true则表示拥有对应的权限，反之则无。Spring Security可用表达式对象的基类是SecurityExpressionRoot，其为我们提供了如下在使用Spring EL表达式对URL或方法进行权限控制时通用的内置表达式。

| **表达式**                     | **描述**                                                     |
| ------------------------------ | ------------------------------------------------------------ |
| hasRole([role])                | 当前用户是否拥有指定角色。                                   |
| hasAnyRole([role1,role2])      | 多个角色是一个以逗号进行分隔的字符串。如果当前用户拥有指定角色中的任意一个则返回true。 |
| hasAuthority([auth])           | 等同于hasRole                                                |
| hasAnyAuthority([auth1,auth2]) | 等同于hasAnyRole                                             |
| principle                      | 代表当前用户的principle对象                                  |
| authentication                 | 直接从SecurityContext获取的当前Authentication对象            |
| permitAll                      | 总是返回true，表示允许所有的                                 |
| denyAll                        | 总是返回false，表示拒绝所有的                                |
| isAnonymous()                  | 当前用户是否是一个匿名用户                                   |
| isRememberMe()                 | 表示当前用户是否是通过Remember-Me自动登录的                  |
| isAuthenticated()              | 表示当前用户是否已经登录认证成功了。                         |
| isFullyAuthenticated()         | 如果当前用户既不是一个匿名用户，同时又不是通过Remember-Me自动登录的，则返回true。 |

##### 1、WEB(即URL)安全控制

```xml
<http >
	<!-- 当前用户必须有ROLE_USER的角色 才可以访问根目录及所属子目录的资源 -->
	<intercept-url pattern="/**" access="hasRole('USER')" />
</http>
```



##### 2、方法安全控制

​	Spring Security中定义了四个支持使用表达式的注解，分别是**@PreAuthorize**、**@PostAuthorize**、**@PreFilter**和**@PostFilter**。其中前两者可以用来在方法调用前或者调用后进行权限检查，后两者可以用来对集合类型的参数或者返回值进行过滤。要使它们的定义能够对我们的方法的调用产生影响我们需要设置global-method-security元素的pre-post-annotations=”enabled”，默认为disabled。

```xml
	<global-method-security pre-post-annotations="enabled" secured-annotations="enabled">
		
	</global-method-security>
```

​	以上注解主要作用在Service层的接口或类以及它们的方法上。

###### 1）、@PreAuthorize

service方法调用前进行权限校验。实例代码如下：

```java
@Service
public class UserServiceImpl implements UserService {
    //只有拥有角色ROLE_ADMIN的用户才能访问
   @PreAuthorize("hasRole('ROLE_ADMIN')")
   public void addUser(User user) {
      System.out.println("addUser................" + user);
   }
   //需要有ROLE_USER角色或ROLE_ADMIN角色，就能访问
   @PreAuthorize("hasRole('ROLE_USER') or hasRole('ROLE_ADMIN')")
   public User find(int id) {
      System.out.println("find user by id............." + id);
      return null;
   }
}
```

或

```java
/**
    * 限制只能查询Id小于10的用户
    */
   @PreAuthorize("#id<10")
   public User find(int id) {
      System.out.println("find user by id........." + id);
      return null;
   }
   /**
    * 限制只能查询自己的信息
    */
   @PreAuthorize("principal.username.equals(#username)")
   public User find(String username) {
      System.out.println("find user by username......" + username);
      return null;
   }
   /**
    * 限制只能新增用户名称为abc的用户
    */
   @PreAuthorize("#user.name.equals('abc')")
   public void add(User user) {
      System.out.println("addUser............" + user);
   }
}
```

###### 2）、@PostAuthorize

有时候可能你会想在方法调用完之后进行权限检查，这种情况比较少，但是如果你有的话，Spring
Security也为我们提供了支持，通过@PostAuthorize可以达到这一效果。使用@PostAuthorize时我们可以使用内置的表达式returnObject表示方法的返回值。我们来看下面这一段示例代码。

```java
@PostAuthorize("returnObject.id%2==0")
public User find(int id) {
    User user = new User();
    user.setId(id);
    return user;
}
```

###### 3）、使用@PreFilter和@PostFilter进行过滤

使用@PreFilter和@PostFilter可以对集合类型的参数或返回值进行过滤。使用@PreFilter和@PostFilter时，Spring Security将移除使对应表达式的结果为false的元素。

```java
   @PostFilter("filterObject.id%2==0")
   public List<User> findAll() {
      List<User> userList = new ArrayList<User>();
      User user;
      for (int i=0; i<10; i++) {
         user = new User();
         user.setId(i);
         userList.add(user);
      }
      return userList;
   }
    /*
    上述代码表示将对返回结果中id不为偶数的user进行移除。filterObject是使用@PreFilter和@PostFilter时的一个内置表达式，表示集合中的当前对象。当@PreFilter标注的方法拥有多个集合类型的参数时，需要通过@PreFilter的filterTarget属性指定当前@PreFilter是针对哪个参数进行过滤的。如下面代码就通过filterTarget指定了当前@PreFilter是用来过滤参数ids的
    */
   @PreFilter(filterTarget="ids", value="filterObject%2==0")
   public void delete(List<Integer> ids, List<String> usernames) {
      ...
   }

```



### 10.3、自定义授权

https://blog.csdn.net/zsq520520/article/details/77881664

#### 第一步、自定义FilterInvocationSecurityMetadataSource从数据库读取权限数据

```java
public class MyFilterInvocationSecurityMetadataSource implements FilterInvocationSecurityMetadataSource,InitializingBean {

    private final static List<ConfigAttribute> NULL_CONFIG_ATTRIBUTE = null;//MethodSecurityMetadataSource

    //资源权限集合
    private Map<RequestMatcher,Collection<ConfigAttribute>> requestMap;

    //查找数据库权限和资源的关系
    private JdbcRequestMapBulider bulider;

    /**
     * 更具访问资源的地址查找所需要的权限
     */
    public Collection<ConfigAttribute> getAttributes(Object object) throws IllegalArgumentException {
        final HttpServletRequest request = ((FilterInvocation) object) .getRequest();
        Collection<ConfigAttribute> atts = NULL_CONFIG_ATTRIBUTE;
        for(Map.Entry<RequestMatcher,Collection<ConfigAttribute>> entry : requestMap.entrySet()){
            if(entry.getKey().matches(request)){
                atts = entry.getValue();
                break;
            }
        }
        return atts;
    }

    /**
     * 获取所有的权限
     * @return
     */
    public Collection<ConfigAttribute> getAllConfigAttributes() {
        Set<ConfigAttribute> attributes = new HashSet<ConfigAttribute>();
        for(Map.Entry<RequestMatcher,Collection<ConfigAttribute>> entry : requestMap.entrySet()){
            attributes.addAll(entry.getValue());
        }
        System.out.println("总共有这些权限："+attributes.toString());
        return attributes;
    }

    public boolean supports(Class<?> aClass) {
        return FilterInvocation.class.isAssignableFrom(aClass);
    }

    //绑定requestMap
    protected Map<RequestMatcher, Collection<ConfigAttribute>> bindRequestMap() {

        return bulider.buildRequestMap();
    }

    public void afterPropertiesSet() throws Exception {
        this.requestMap = this.bindRequestMap();
    }

    public void refreshResuorceMap() {
        this.requestMap = this.bindRequestMap();
    }

    public JdbcRequestMapBulider getBulider() {
        return bulider;
    }

    public void setBulider(JdbcRequestMapBulider bulider) {
        this.bulider = bulider;
    }
}
```

#### 第二步、定义JdbcRequestMapBulider从数据库读取权限数据

```java
public class JdbcRequestMapBulider extends JdbcDaoSupport {
    //查询数据的sql语句，该属性在配置bean的时候传入即可。
    private String resourceQuery = "";

    public String getResourceQuery() {
        return resourceQuery;
    }

    public void setResourceQuery(String resourceQuery) {
        this.resourceQuery = resourceQuery;
    }

    //查询资源的方法
    public List<Resource> findResourceData(){
        ResourceMapping resourceMapping = new ResourceMapping(getDataSource(),resourceQuery);

        return resourceMapping.execute();
    }

    /**
     * 拼接RequestMap
     * buildRequestMap方法用来最后拼接成LinkedHashMap<RequestMatcher, Collection<ConfigAttribute>>共security使用。
     * @return
     */
    public LinkedHashMap<RequestMatcher,Collection<ConfigAttribute>> buildRequestMap(){
        LinkedHashMap<RequestMatcher,Collection<ConfigAttribute>> requestMap =
                new LinkedHashMap<RequestMatcher, Collection<ConfigAttribute>>();
        List<Resource> resourcesList = this.findResourceData();//查询资源信息
        for(Resource resource : resourcesList){
            RequestMatcher requestMatcher = this.getRequestMatcher(resource.getUrl());
            List<ConfigAttribute> list = new ArrayList<ConfigAttribute>();
            list.add(new SecurityConfig(resource.getRole()));
            requestMap.put(requestMatcher,list);
        }
        return requestMap;
    }

    //通过一个字符串地址构建一个AntPathRequestMatcher对象
    //getRequestMatcher方法就是用来创建RequestMatcher对象的
    protected RequestMatcher getRequestMatcher(String url){
        return new AntPathRequestMatcher(url);
    }
}
```

```java
public class ResourceMapping extends MappingSqlQuery {
    public ResourceMapping(DataSource dataSource, String resourceQuery) {
        super(dataSource,resourceQuery);
        compile();
    }

    /**
     * //对结果集进行封装处理
     * @param rs
     * @param i
     * @return
     * @throws SQLException
     */
    protected Object mapRow(ResultSet rs, int i) throws SQLException {
        String url = rs.getString(1);
        String role = rs.getString(2);
        Resource resource = new Resource(url,role);
        return resource;
    }
}
```

```java
public class Resource {
    private String url;//资源访问的地址

    private String role;//所需要的权限

    public Resource(String url, String role) {
        this.url = url;
        this.role = role;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}
```

#### 第三步、配置Spring Security

```xml
<beans:bean id="filterSecurityInterceptor"
				class="org.springframework.security.web.access.intercept.FilterSecurityInterceptor">
		<!-- 用户拥有的权限 -->
		<beans:property name="accessDecisionManager" ref="accessDecisionManager" />
		<!-- 用户是否拥有所请求资源的权限 -->
		<beans:property name="authenticationManager" ref="authenticationManager" />
		<!-- 资源与权限对应关系 -->
		<beans:property name="securityMetadataSource" ref="securityMetadataSource" />
	</beans:bean>

	<beans:bean id="accessDecisionManager" class="org.springframework.security.access.vote.AffirmativeBased">
		<beans:constructor-arg>
			<beans:list>
				<beans:bean class="org.springframework.security.access.vote.RoleVoter">
					<beans:property name="rolePrefix" value=""/>
				</beans:bean>
				<beans:bean class="org.springframework.security.access.vote.AuthenticatedVoter"/>
				<beans:bean class="org.springframework.security.web.access.expression.WebExpressionVoter"></beans:bean>
			</beans:list>
		</beans:constructor-arg>
	</beans:bean>

	<!--自定义的切入点-->
	<beans:bean id="securityMetadataSource"
				class="com.itcast.security.MyFilterInvocationSecurityMetadataSource">
		<beans:property name="bulider" ref="bulider"></beans:property>
	</beans:bean>

	<beans:bean id="bulider" class="com.itcast.security.JdbcRequestMapBulider">
		<beans:property name="dataSource" ref="mysqlDataSource"></beans:property>
		<beans:property name="resourceQuery"
						value="select re.res_string,r.`name` from role r,resc re,resc_role rr
                                where r.id=rr.role_id and re.id=rr.resc_id"></beans:property>
	</beans:bean>

	<!-- 数据库连接池 -->
	<!-- 加载配置文件 -->
	<context:property-placeholder location="classpath*:properties/*.properties" />
	<!-- 数据库连接池 -->
	<beans:bean id="mysqlDataSource" class="com.alibaba.druid.pool.DruidDataSource"
				destroy-method="close">
		<beans:property name="url" value="${jdbc.url}" />
		<beans:property name="username" value="${jdbc.username}" />
		<beans:property name="password" value="${jdbc.password}" />
		<beans:property name="driverClassName" value="${jdbc.driver}" />
		<beans:property name="maxActive" value="10" />
		<beans:property name="minIdle" value="5" />
	</beans:bean>
```



## 十一、退出登录

```
<logout>
添加LogoutFilter过滤器
	delete-cookies	退出登录后需要被删除的cookie名称，多个用逗号分隔
	invalidate-session	退出登录后是否session失效，默认是true
	logout-success-url	退出登录成功后，跳转的页面
	logout-url	退出登录的URL，默认是/logout
	success-handler-ref	指定LogoutSuccessHandler
```

# 第二章 spring security + cas



## 一、spring security整合cas实现一个用户同时只能登录一次

​	先说说如何实现一个用户同时只能登录一次，传统单系统应用的解决方案，大体思路是将用户与session或ip与session进行绑定。这样一个用户或一个ip通知只能有一个有效的session。

### 	1、spring security的解决方案。

​	spring security默认提供可session管理机制。我们可以通过设置保证当前用户只能有一个活跃session。如果用户在其他地方登陆。就会导致用户之前登陆的session失效。从而实现挤出登录的功能。

​	![](spring security单用户登录.jpg)

​	

### 	2、spring security整合cas实现

​	spring security在集成了cas之后。此时如果需要实现一个用户同时只能登录一次的话。使用之前的spring security的session管理机制是无法实现的。因为cas实现单点登录后，用户是否登录的状态是由cas服务器中保存的TGT（票据授权票据）来决定的。所有如果只是单纯的删除之前用户登录的session是无法实现挤出登录的。

​	我们需要做的是将TGT与登录用户进行绑定，一个用户只能同时有一个TGT存在，如果用户在其他地方再次进行登录。我们就将上次用户登录的TGT从CAS服务器中删除，从而实现挤出登录的效果。

![](cas单用户登录.jpg)

​	

#### 2.1、如果要完成CAS单用户的功能需要对CAS进行源码修改：

```java
org.jasig.cas.CentralAuthenticationServiceImpl
```

 在这个类中首先先验证用户名，密码。然后进行创建TGT,ST,然后在缓存TGT,并且ST有效性的验证，以及销毁TGT都是在这个类中，所以这个类可以说是CAS的核心类了；我们对这个类做如下修改：

```java
public  class CentralAuthenticationServiceImpl implements CentralAuthenticationService {

   
   。。。。。。
        
    /**
     * @throws IllegalArgumentException if the credentials are null.
     * 该方法是创建TGT的。我们可以在创建TGT时，删除用户之前的TGT
     */
    @Audit(
        action="TICKET_GRANTING_TICKET",
        actionResolverName="CREATE_TICKET_GRANTING_TICKET_RESOLVER",
        resourceResolverName="CREATE_TICKET_GRANTING_TICKET_RESOURCE_RESOLVER")
    @Profiled(tag = "CREATE_TICKET_GRANTING_TICKET", logFailuresSeparately = false)
    @Transactional(readOnly = false)
    public String createTicketGrantingTicket(final Credential... credentials)
            throws AuthenticationException, TicketException {//生成TGT的方法

        Assert.notNull(credentials, "credentials cannot be null");

        final Authentication authentication = this.authenticationManager.authenticate(credentials);

        final TicketGrantingTicket ticketGrantingTicket = new TicketGrantingTicketImpl(
            this.ticketGrantingTicketUniqueTicketIdGenerator
                .getNewTicketId(TicketGrantingTicket.PREFIX),
            authentication, this.ticketGrantingTicketExpirationPolicy);

        //====== 删除用户上一次的TGT add by 春哥 ======
        String uid = credentials[0].getId();
        Ticket ticket = this.ticketRegistry.getTicket(uid);//根据用户查找
        if(ticket != null){
            this.destroyTicketGrantingTicket(ticket.getId());
        }
        //======= end ======

        this.ticketRegistry.addTicket(ticketGrantingTicket);
        return ticketGrantingTicket.getId();
    }

   。。。。。。
}
```

我们还需要修改下面这个类：

```
org.jasig.cas.ticket.registry.DefaultTicketRegistry
```

这个类主要是进行管理和存储TGT和ST,以及记录TGT和ST之间的关系，及通过tickeid查询ticket,添加ticket,删除ticked等

```java
public final class DefaultTicketRegistry extends AbstractTicketRegistry  {

    /** A HashMap to contain the tickets. */
    private final Map<String, Ticket> cache; //票据存储的容器

    /** ======== 保存用户名与票据ID对应关系 保证用户名和TGT是唯一对应的 add by 春哥 ========*/
    private final Map<String, String> nameIdCache;

    public DefaultTicketRegistry() {
        this.cache = new ConcurrentHashMap<String, Ticket>();
         /** ======== 初始化 add by 春哥 ========*/
        this.nameIdCache = new ConcurrentHashMap<String, String>();
    }

    /**
     * Creates a new, empty registry with the specified initial capacity, load
     * factor, and concurrency level.
     *
     * @param initialCapacity - the initial capacity. The implementation
     * performs internal sizing to accommodate this many elements.
     * @param loadFactor - the load factor threshold, used to control resizing.
     * Resizing may be performed when the average number of elements per bin
     * exceeds this threshold.
     * @param concurrencyLevel - the estimated number of concurrently updating
     * threads. The implementation performs internal sizing to try to
     * accommodate this many threads.
     */
    public DefaultTicketRegistry(final int initialCapacity, final float loadFactor, final int concurrencyLevel) {
        this.cache = new ConcurrentHashMap<String, Ticket>(initialCapacity, loadFactor, concurrencyLevel);
        /** ======== 初始化 add by 春哥 ========*/
        this.nameIdCache = new ConcurrentHashMap<String, String>();
    }

    /**
     * {@inheritDoc}
     * @throws IllegalArgumentException if the Ticket is null.
     */
    @Override
    public void addTicket(final Ticket ticket) {
        Assert.notNull(ticket, "ticket cannot be null");

        logger.debug("Added ticket [{}] to registry.", ticket.getId());
        this.cache.put(ticket.getId(), ticket);

        //======== 保存username 和 TGT 的关系 add by 春哥 ========
        if(ticket instanceof TicketGrantingTicket){
            String username = ((TicketGrantingTicket)ticket).getAuthentication().getPrincipal().toString().trim();
            this.nameIdCache.put(username, ticket.getId());
        }
        //======== end ========

    }

    public Ticket getTicket(final String ticketId) {
        if (ticketId == null) {
            return null;
        }

        logger.debug("Attempting to retrieve ticket [{}]", ticketId);
        final Ticket ticket = this.cache.get(ticketId);

        if (ticket != null) {
            logger.debug("Ticket [{}] found in registry.", ticketId);
        }

        //======== 根据用户ID获取当前TGT 并返回  add by 春哥 ========
        final String tid = this.nameIdCache.get(ticketId);
        if(tid != null){
            final Ticket ticketU = this.cache.get(tid);

            if(ticketU != null) {
                logger.debug("Ticket [{}] found in registry.", ticketId);
                return ticketU;
            }
        }
        // ======== end ========

        return ticket;
    }

    public boolean deleteTicket(final String ticketId) {
        if (ticketId == null) {
            return false;
        }
        logger.debug("Removing ticket [{}] from registry", ticketId);

        final Ticket ticket = getTicket(ticketId);
        if (ticket == null) {
            return false;
        }
        // ======== 删除当前用户TGT add by 春哥 ========
        if (ticket instanceof TicketGrantingTicket) {
            logger.debug("Removing children of ticket [{}] from the registry.", ticket);
            deleteChildren((TicketGrantingTicket) ticket);
            // 根据用户名从nameIdCache中删除当前用户对应的TGT
            String username = ((TicketGrantingTicket)ticket).getAuthentication().getPrincipal().toString().trim();
            this.nameIdCache.remove(username);
        }
        //======== end ========

        return (this.cache.remove(ticketId) != null);
    }

    //======== 从cache中删除当前用户对应的TGT add by 春哥 ========
    private void deleteChildren(final TicketGrantingTicket ticket) {
        // delete service tickets
        final Map<String, Service> services = ticket.getServices();
        if (services != null && !services.isEmpty()) {
            for (final Map.Entry<String, Service> entry : services.entrySet()) {
                if (this.cache.remove(entry.getKey()) != null) {
                    logger.trace("Removed service ticket [{}]", entry.getKey());
                } else {
                    logger.trace("Unable to remove service ticket [{}]", entry.getKey());
                }
            }
        }
    }
    //======== end ========

    public Collection<Ticket> getTickets() {
        return Collections.unmodifiableCollection(this.cache.values());
    }

    public int sessionCount() {
        int count = 0;
        for (Ticket t : this.cache.values()) {
            if (t instanceof TicketGrantingTicket) {
                count++;
            }
        }
        return count;
    }

    public int serviceTicketCount() {
        int count = 0;
        for (Ticket t : this.cache.values()) {
            if (t instanceof ServiceTicket) {
                count++;
            }
        }
        return count;
    }
}
```

#### 2.2、修改完成后需要将者两个类，编译成class文件，放入cas对应的部署目录下。

```java
.\apache-tomcat-cas\webapps\cas\WEB-INF\classes\org\jasig\cas\ticket\registry\DefaultTicketRegistry.class

.\apache-tomcat-cas\webapps\cas\WEB-INF\classes\org\jasig\cas\CentralAuthenticationServiceImpl.class

```



# 第二章	spring security oauth2功能介绍和原理解析

http://www.cnblogs.com/linianhui/p/oauth2-authorization.html

https://www.cnblogs.com/xingxueliao/p/5911292.html

## 一、OAuth2概述

OAuth2 是一个**开放授权标准，**它允许用户（小明）让第三方应用（学成教育）访问该用户在某服务的**特定私有资源**（小明的微信）但是不提供账号密码信息给第三方应用（学成教育）。



## 二、OAuth2 角色

### 1、OAuth2 标准中的角色

- 资源所有者（Resource Owner）

  通常为用户，也可以是应用程序，即该资源的拥有者。

- 资源服务器（Resource Server）

  存储资源的服务器，比如，学成网用户管理服务器存储了学成网的用户信息，学成网学习服务器存储了学生的学习信息，微信的资源服务存储了微信的用户信息等。客户端最终访问资源服务器获取资源信息。

- 授权服务器（Authorization Server）

  用来对资源拥有的身份进行认证、对访问资源进行授权。客户端要想访问资源需要通过认证服务器由资源拥有者授权后方可访问。

- 客户端（Client）

  在 OAuth 2 中，客户端即代表意图访问受限资源的第三方应用。在访问实现之前，它必须先经过用户者授权，并且获得的授权凭证将进一步由授权服务器进行验证。


### 2、部署OAuth2应用时每个角色需要实现的功能

#### 2.1、授权服务器（Authorization Server）

Authorization server服务，主要提供两类接口

1. 授权接口：接受Client的授权请求，引导用户到Resource server完成登陆授权的过程。
2. 获取访问令牌接口：使用授权接口提供的许可凭据来颁发Resource owner的访问令牌给Client，或者由Client更新过期的访问令牌。
3. 除此之外，还需要提供一个第三方应用程序注册管理的服务。通常情况下会为注册完成的第三方应用程序分配两个成对出现的重要参数：
   1. client_id：第三方应用程序的一个标识id，这个信息通常是公开的信息，用来区分哪一个第三方应用程序。
   2. client_secret：第三方应用程序的私钥信息，这个信息是私密的信息，不允许在OAuth2流程中传递的，用于安全方面的检测和加密。

#### 2.2、资源服务器（Resource Server）

资源服务器（Resource Server）需要开放相应的受保护资源的可访问API。

#### 2.3、客户端（Client）

Client 注册成为Resource server的第三方应用。

Client 消费这些API



## 三、OAuth2授权流程

![](oauth2流程图片.jpg)

A、客户端请求第三方授权

B、资源拥有者同意给客户端授权

C、客户端获取到授权码，请求认证服务器申请令牌

D、认证服务器（在确定授权码有效后）向客户端响应令牌

E、客户端（带着令牌）请求资源服务器的资源

F、资源服务器（在确定令牌有效后）返回受保护资源



## 四、授权许可

**授权许可是一个代表资源所有者授权（访问受保护资源）的凭据，客户端用它来获取访问令牌**。授权许可类型取决于应用请求授权的方式和授权方服务支持的 Grant Type。OAuth 2 定义了四种 Grant Type，每一种都有适用的应用场景。

### 4.1、授权码模式（Authorization Code）

结合普通服务器端应用使用。这是OAuth2最常用的一种授权许可类型，比如QQ，微博，Facebook和豆瓣等等。要求Client具有可公开访问的Server服务器来接受**Authorization Code**

![](授权码模式.jpg)



#### A、**Client**使用浏览器（用户代理）访问**Authorization server**

客户端提供以下参数请求Authorization Server：

1. response_type：必选。值固定为“code”。
2. client_id：必选。第三方应用的标识ID。
3. state：**推荐**。Client提供的一个字符串，服务器会原样返回给Client。
4. redirect_uri：必选。授权成功后的重定向地址。
5. scope：可选。表示授权范围。

如下：

```html
localhost:40400/auth/oauth/authorize?client_id=XcWebApp&response_type=code&scope=app&redirect_uri=http://localhost
```



#### B、用户同意授权

**Authorization server**验证**Client**在（A）中传递的参数信息，如果无误则提供一个页面供**Resource owner**登陆，登陆成功后选择**Client**可以访问**Resource server**的哪些资源以及读写权限。

首先跳转到登录页面：

![](oauth2_code_login.png)

输入资源拥有者的账号和密码，点击Login。

![](oauth2_code_confirm.png)



#### C、返回授权码

点击“Authorize”同意，接下来返回授权码：

![](oauth2_code_code.png)



#### D、申请令牌

拿到授权码后，申请令牌。post请求：<http://localhost:40400/auth/oauth/token>，参数如下：

- grant_type：授权类型，填写authorization_code，表示授权码模式
- code：授权码，就是刚刚获取的授权码，注意：授权码只使用一次就无效了，需要重新申请。
- redirect_uri：申请授权码时的跳转url，一定和申请授权码时用的redirect_uri一致。



#### E、响应令牌

```json
{
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55SWQiOm51bGwsInVzZXJwaWMiOm51bGwsInVzZXJfbmFtZSI6ImFkbWluIiwic2NvcGUiOlsiYXBwIl0sIm5hbWUiOm51bGwsInV0eXBlIjpudWxsLCJpZCI6bnVsbCwiZXhwIjoxNTUyNzkyNDA4LCJqdGkiOiJkMDFkZTM0MS01N2M2LTRhMzItOGI5Yy1kMTBlM2ZjZjYyNDgiLCJjbGllbnRfaWQiOiJYY1dlYkFwcCJ9.WQf_juZQ7nan5uHfKuSlkynESKH3eQ5rocdA6rQLC2FeaZXVE0L-U3rd9fPCKjaPiARXcUJldeZJDsNSCgMZbK0z_wtA-342UyTLmaAlZDavVEwI7z0xuQYgl3HteQQN8PD_94JwfyjOYwI_sPBwRkx36EuGGh1qKT-f3k-xPs-_fGGo1tLB4O484GuTWDQgjni59YXlHOoj8PuNF7s-yhHuPZiZQuGyhdRYGAsyp_RyrdsTWCYNRolq5PYve8lLeU-epl1-uTRDwhd_YfJyCgB9IgbIQBOfI-VlLu_HQogKXaTxW10Kmg0jHNoHfTF7P18_TkqEHFd1dP7VcoMueA",
    "token_type": "bearer",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55SWQiOm51bGwsInVzZXJwaWMiOm51bGwsInVzZXJfbmFtZSI6ImFkbWluIiwic2NvcGUiOlsiYXBwIl0sImF0aSI6ImQwMWRlMzQxLTU3YzYtNGEzMi04YjljLWQxMGUzZmNmNjI0OCIsIm5hbWUiOm51bGwsInV0eXBlIjpudWxsLCJpZCI6bnVsbCwiZXhwIjoxNTUyNzkyNDA4LCJqdGkiOiI0YTIyYWI3MC01ZDMwLTRmMDEtYTg3My0xYzJiZmFlYjNhNjYiLCJjbGllbnRfaWQiOiJYY1dlYkFwcCJ9.PPQU3Z20BzyWtdc0bxdPDyelzBw0Zhu4SXIoYoZx_ka0rqrEZSPOhxrRuB2VUtDaAWksP1C2NAdoFqI7W0tfXFxKCqEoPIcfT62Bhy5AjdAwt8PaIURrOKbQ60KgroP4u2-80QLacX3hkQgtef893qCYlDS7Oazp3N4XAilgcgdEF-iIgOKcdVvwWPbRJFhEMnLPnKjpT5_ZrEqvcdqYG2l8krwZ-YlmrOSqDqd5nE3ViVgRKK5-gp-Gjw5NOc7a1_a8bhJYyWU1VhG6-LwXN1uSWV2B-iSpwki0tuz2169kaWDd2TT51UO7uYzyJdMs4LpwcoVgX4URy5qOkgKxGw",
    "expires_in": 43189,
    "scope": "app",
    "jti": "d01de341-57c6-4a32-8b9c-d10e3fcf6248"
}
```

access_token：访问令牌，携带此令牌访问资源

token_type：有MAC Token与Bearer Token两种类型，两种的校验算法不同，RFC 6750建议Oauth2采用 Bearer Token（<http://www.rfcreader.com/#rfc6750>）。

refresh_token：刷新令牌，使用此令牌可以延长访问令牌的过期时间。

expires_in：过期时间，单位为秒。

scope：范围，与定义的客户端范围一致。



### 4.2、隐式授权模式（Implicit）

这个是Authorization Code的简化版本。其中省略掉了颁发授权码（Authorization Code）给客户端的过程，而是直接返回访问令牌和可选的刷新令牌。其适用于没有Server服务器来接受处理Authorization Code的第三方应用，其流程如下：

![](隐式模式.jpg)

其步骤就不做详细介绍了，相信大家都能理解。和Authorzation Code类型下重要的区分就是省略了Authorization Response和Access Token Request。而是直接由Authorization Request返回Access Token Response信息，具体如下。

#### 4.2.1、发送授权请求

客户端提供以下参数请求Authorization Server：

1. response_type：必选。值固定为“token”。
2. client_id：必选。第三方应用的标识ID。
3. state：**推荐**。Client提供的一个字符串，服务器会原样返回给Client。
4. redirect_uri：可选。授权成功后的重定向地址。
5. scope：可选。表示授权范围。

重点区别在于**response_type为“token”**，而不再是“code”，redirect_uri也变为了可选参数。

比如以下示例：

```html
localhost:40400/auth/oauth/authorize?client_id=XcWebApp&response_type=token&scope=app&redirect_uri=http://localhost
```

#### 4.2.2、响应令牌

```html
http://localhost/#access_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55SWQiOm51bGwsInVzZXJwaWMiOm51bGwsInVzZXJfbmFtZSI6ImFkbWluIiwic2NvcGUiOlsiYXBwIl0sIm5hbWUiOm51bGwsInV0eXBlIjpudWxsLCJpZCI6bnVsbCwiZXhwIjoxNTUyNzk0NDYzLCJqdGkiOiIwOGYzOTZmMi1iNDUzLTQ4ZGUtYTRjMi0zOTk4MjdmMTE5NzkiLCJjbGllbnRfaWQiOiJYY1dlYkFwcCJ9.V1fTDYOum8TdSTovZKOCCyjSrtNJt94QsCr8evj-1l4YT82PhGuoY9y2D65ODzrjrtysHPUtCeChfPcjXfw6DpgY-wMTUZ1zHEaMnaqW9Xh_wlvLtaXN787gF7Q5qagVAAeUWDtHYakx-2wU9KbwQjbWXfmSRbS3Y23Xmxa3qCgr-l7LU9jV5k6unjIe2bQV0N5WQcms8XVJbgA0LQ1m0m3Sec5ZJEaEYUsTnyRTWkBliP0SW3SI7lcNqIwgv-RiYUTPs7g0Ru-MGw4l8_sUgwiQZIjxg9Cd4s4zGnBvNkWfDtZIvyMW-3LD6LQ-rCmzo7hi8j5UdLDlAzrMX8dEag&token_type=bearer&expires_in=43199&jti=08f396f2-b453-48de-a4c2-399827f11979
```



### 4.3、密码模式（Resource Owner Password Credentials）

![](密码模式.jpg)

这种模式再一步简化，和Authorzation Code类型下重要的区分就是省略了Authorization Request和Authorization Response。而是Client直接使用Resource owner资源拥有者提供的username和password来直接请求access_token（直接发起Access Token Request然后返回Access Token Response信息）。这种模式一般适用于Resource server高度信任第三方Client的情况下。

客户端提供以下参数请求Authorization Server：

1. grant_type：必选。值固定为“password”。
2. username：必选。用户登陆名。
3. passward：必选**。**用户登陆密码。
4. scope：可选。表示授权范围。
5. 并且此链接需要使用 http Basic认证。需要使用客户端id和客户端密码

示例：

```
POST:http://localhost:40400/auth/oauth/token
```



### 4.4、客户端模式（Client Credentials）

这种类型就更简化了，Client直接已自己的名义而不是Resource owner的名义去要求访问Resource server的一些受保护资源。

![](客户端模式.jpg)

客户端提供以下参数请求Authorization Server：

1. grant_type：必选。值固定为“client_credentials”。
2. scope：可选。表示授权范围。
3. 并且此链接需要使用 http Basic认证。需要使用客户端id和客户端密码

比如以下示例：

```
POST:http://localhost:40400/auth/oauth/token
```

这个场景下得到的access_token的所属人是公众号的，可以用此access_token来获取所有已关注的用户的信息，而不局限于特定的某一个用户，正是Client Credentials Grant这种类型的许可的用武之地



### 4.5、源码分析

![](oauth授权流程图.png)



## 五、令牌校验

### 5.1、服务端校验

![](令牌校验1.png)

用户每次请求资源服务，资源服务都需要携带令牌访问认证服务去校验令牌的合法性，并根据令牌获取用户的相关信息。Spring Security Oauth2提供校验令牌的端点，如下：

Get: <http://localhost:40400/auth/oauth/check_token?token=>

校验结果如下：

```
{
    "companyId": null,
    "userpic": null,
    "user_name": "mrt",
    "scope": [
        "app"
    ],
    "name": null,
    "utype": null,
    "id": null,
    "exp": 1531254828,
    "jti": "6a00f227-4c30-47dc-a959-c0c147806462",
    "client_id": "XcWebApp",
    "authorities": [
        "xc_teachmanager_course_base",
        "xc_teachmanager_course_del",
        "xc_teachmanager_course_list",
        "xc_teachmanager_course_plan",
        "xc_teachmanager_course",
        "course_find_list",
        "xc_teachmanager",
        "xc_teachmanager_course_market",
        "xc_teachmanager_course_publish",
        "xc_teachmanager_course_add"
    ]
}
```

exp：过期时间，long类型，距离1970年的秒数（new Date().getTime()可得到当前时间距离1970年的毫秒数）。

user_name：  用户名

client_id：客户端Id，在oauth_client_details中配置

scope：客户端范围，在oauth_client_details表中配置

jti：与令牌对应的唯一标识

companyId、userpic、name、utype、id：这些字段是本认证服务在Spring Security基础上扩展的用户身份信息

**authorities：当前令牌可访问的权限列表！！！**



### 5.2、客户端校验--JWT令牌



![](C:\Users\think\Desktop\javaEE16期\springSecurity\令牌校验2.png)

Spring Security 提供对JWT的支持，本节我们使用Spring Security 提供的JwtHelper来创建JWT令牌，校验JWT令牌等操作。

使用JWT的思路是，用户认证通过会得到一个JWT令牌，JWT令牌中已经包括了用户相关的信息，客户端只需要携带JWT访问资源服务，资源服务根据事先约定的算法自行完成令牌校验，无需每次都请求认证服务完成授权。

#### 5.2.1、生成私钥和公钥

JWT令牌生成采用非对称加密算法

**1、生成密钥证书**

下边命令生成密钥证书，采用RSA 算法每个证书包含公钥和私钥

```
keytool -genkeypair -alias xckey -keyalg RSA -keypass xuecheng -keystore xc.keystore -storepass xuechengkeystore
```

Keytool 是一个java提供的证书管理工具

​	 -alias：密钥的别名

​	 -keyalg：使用的hash算法

​	-keypass：密钥的访问密码

​	-keystore：密钥库文件名，xc.keystore保存了生成的证书

​	 -storepass：密钥库的访问密码

查询证书信息：

```
keytool -list -keystore xc.keystore
```

删除别名

```
keytool -delete -alias xckey -keystore xc.keystore
```



**2、导出公钥**

openssl是一个加解密工具包，这里使用openssl来导出公钥信息。

安装 openssl：<http://slproweb.com/products/Win32OpenSSL.html>

下载安装Win64OpenSSL-1_1_0g.exe

配置openssl的path环境变量，本教程配置在D:\OpenSSL-Win64\bin

cmd进入xc.keystore文件所在目录执行如下命令：

```
keytool -list -rfc --keystore xc.keystore | openssl x509 -inform pem -pubkey
```

输入密钥库密码：

![1527048184188](jwt秘钥.png)

下边这一段就是公钥内容：

-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAijyxMdq4S6L1Af1rtB8SjCZHNgsQG8JTfGy55eYvzG0B/E4AudR2prSRBvF7NYPL47scRCNPgLnvbQczBHbBug6uOr78qnWsYxHlW6Aa5dI5NsmOD4DLtSw8eX0hFyK5Fj6ScYOSFBz9cd1nNTvx2+oIv0lJDcpQdQhsfgsEr1ntvWterZt/8r7xNN83gHYuZ6TM5MYvjQNBc5qC7Krs9wM7UoQuL+s0X6RlOib7/mcLn/lFLsLDdYQAZkSDx/6+t+1oHdMarChIPYT1sx9Dwj2j2mvFNDTKKKKAq0cv14Vrhz67Vjmz2yMJePDqUi0JYS2r0iIo7n8vN7s83v5uOQIDAQAB-----END PUBLIC KEY-----

将上边的公钥拷贝到文本文件中，合并为一行。

 

#### 5.2.2、生成jwt令牌

在认证工程创建测试类，测试jwt令牌的生成与验证。

```
//生成一个jwt令牌
@Test
public void testCreateJwt(){
    //证书文件
    String key_location = "xc.keystore";
    //密钥库密码
    String keystore_password = "xuechengkeystore";
    //访问证书路径
    ClassPathResource resource = new ClassPathResource(key_location);
    //密钥工厂
    KeyStoreKeyFactory keyStoreKeyFactory = new KeyStoreKeyFactory(resource, keystore_password.toCharArray());
    //密钥的密码，此密码和别名要匹配
    String keypassword = "xuecheng";
    //密钥别名
    String alias = "xckey";
    //密钥对（密钥和公钥）
    KeyPair keyPair = keyStoreKeyFactory.getKeyPair(alias,keypassword.toCharArray());
    //私钥
    RSAPrivateKey aPrivate = (RSAPrivateKey) keyPair.getPrivate();
    //定义payload信息
    Map<String, Object> tokenMap = new HashMap<>();
    tokenMap.put("id", "123");
    tokenMap.put("name", "mrt");
    tokenMap.put("roles", "r01,r02");
    tokenMap.put("ext", "1");
    //生成jwt令牌
    Jwt jwt = JwtHelper.encode(JSON.toJSONString(tokenMap), new RsaSigner(aPrivate));
    //取出jwt令牌
    String token = jwt.getEncoded();
    System.out.println("token="+token);
}
```

#### 5.2.3、验证jwt令牌

```
//资源服务使用公钥验证jwt的合法性，并对jwt解码
    @Test
    public void testVerify(){
        //jwt令牌
        String token ="";
        //公钥
        String publickey = "";
        //校验jwt
        Jwt jwt = JwtHelper.decodeAndVerify(token, new RsaVerifier(publickey));
        //获取jwt原始内容
        String claims = jwt.getClaims();
        //jwt令牌
        String encoded = jwt.getEncoded();
        System.out.println(encoded);
    }
```



### 5.3、刷新令牌

 在上述得到访问令牌（access_token）时，一般会提供一个过期时间和刷新令牌。以便在访问令牌过期失效的时候可以由客户端自动获取新的访问令牌，而不是让用户再次登陆授权。

Post：<http://localhost:40400/auth/oauth/token>

参数：

- grant_type： 固定为 refresh_token
- refresh_token：刷新令牌（注意不是access_token，而是refresh_token）

刷新令牌成功，会重新生成新的访问令牌和刷新令牌，令牌的有效期也比旧令牌长。刷新令牌通常是在令牌快过期时进行刷新。



## 六、资源服务授权

### 6.1、 资源服务授权流程

资源服务拥有要访问的受保护资源，客户端携带令牌访问资源服务，如果令牌合法则可成功访问资源服务中的资源，如下图：

![1526648744026](资源授权服务流程.png)

上图的业务流程如下：

1、客户端请求认证服务申请令牌

2、授权服务生成令牌

​	授权服务采用非对称加密算法，使用私钥生成令牌。

3、客户端携带令牌访问资源服务

​	客户端在Http header 中添加： Authorization：Bearer 令牌。

4、资源服务校验令牌的有效性

​	资源服务接收到令牌，使用公钥校验令牌的合法性。

5、令牌有效，资源服务向客户端响应资源信息

 

### 6.2 、资源服务授权配置

1、配置公钥

认证服务生成令牌采用非对称加密算法，认证服务采用私钥加密生成令牌，对外向资源服务提供公钥，资源服务使用公钥 来校验令牌的合法性。

将公钥拷贝到 publickey.txt文件中，将此文件拷贝到资源服务工程的classpath下

2、添加依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-oauth2</artifactId>
</dependency>
```

3、在config包下创建ResourceServerConfig类：

```java
@Configuration
@EnableResourceServer
@EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true)//激活方法上的PreAuthorize注解
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {
    //公钥
    private static final String PUBLIC_KEY = "publickey.txt";

    //定义JwtTokenStore，使用jwt令牌
    @Bean
    public TokenStore tokenStore(JwtAccessTokenConverter jwtAccessTokenConverter) {
        return new JwtTokenStore(jwtAccessTokenConverter);
    }

    //定义JJwtAccessTokenConverter，使用jwt令牌
    @Bean
    public JwtAccessTokenConverter jwtAccessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setVerifierKey(getPubKey());
        return converter;
    }
    /**
     * 获取非对称加密公钥 Key
     * @return 公钥 Key
     */
    private String getPubKey() {
        Resource resource = new ClassPathResource(PUBLIC_KEY);
        try {
            InputStreamReader inputStreamReader = new InputStreamReader(resource.getInputStream());
            BufferedReader br = new BufferedReader(inputStreamReader);
            return br.lines().collect(Collectors.joining("\n"));
        } catch (IOException ioe) {
            return null;
        }
    }
    //Http安全配置，对每个到达系统的http请求链接进行校验
    @Override
    public void configure(HttpSecurity http) throws Exception {
        //所有请求必须认证通过
        http.authorizeRequests().anyRequest().authenticated();
    }
}
```





###  6.3、资源服务器授权原理解析

![](资源授权流程.jpg)

1、客户端请求资源服务被OAuth2AuthenticationProcessingFilter拦截

```java
public class OAuth2AuthenticationProcessingFilter implements Filter, InitializingBean {
	public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException,ServletException {
	try {
		Authentication authentication = tokenExtractor.extract(request);
		if (authentication == null) {
			......
		}
		else {
			......
            //认证管理器进行认证
			Authentication authResult = authenticationManager.authenticate(authentication);
            ......
			}
		}
		catch (OAuth2Exception failed) {
			......
		}
		chain.doFilter(request, response);
	}

}
```

2、OAuth2AuthenticationManager进行认证

```java
public class OAuth2AuthenticationManager implements AuthenticationManager, InitializingBean {
    //认证
	public Authentication authenticate(Authentication authentication) throws AuthenticationException {
		if (authentication == null) {
			throw new InvalidTokenException("Invalid token (token not found)");
		}
        //获取令牌
		String token = (String) authentication.getPrincipal();
        //校验令牌
		OAuth2Authentication auth = tokenServices.loadAuthentication(token);
		if (auth == null) {
			throw new InvalidTokenException("Invalid token: " + token);
		}
		......
		//认证通过
		auth.setAuthenticated(true);
		return auth;

	}
}
```



