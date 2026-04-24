package com.fishclicks.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling; // 1. Importa esto

@SpringBootApplication
@EnableScheduling // 2. Activa la programación de tareas
public class FishClicksApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(FishClicksApiApplication.class, args);
	}
}