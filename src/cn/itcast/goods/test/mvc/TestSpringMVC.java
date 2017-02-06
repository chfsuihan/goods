package cn.itcast.goods.test.mvc;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
@Controller
@RequestMapping("/spring")
public class TestSpringMVC {
	public TestSpringMVC() {
		System.out.println("TestSpringMVC init~~~~~~~~~~~~~~~~");
	}
	@RequestMapping("/test")
	public String testSpringMVC(){
		return "testSpringMVC";
	}
}
