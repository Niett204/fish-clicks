package com.fishclicks.api.dto;

import lombok.Data;

import java.util.List;

@Data
public class PecesRequest {
    private List<Long> peces;
}