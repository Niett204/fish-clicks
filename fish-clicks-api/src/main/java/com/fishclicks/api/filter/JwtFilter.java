package com.fishclicks.api.filter;

import com.fishclicks.api.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private static final Logger logger = (Logger) LoggerFactory.getLogger(JwtFilter.class);

    @Autowired
    private JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        String path = request.getRequestURI();
        logger.info("JWT Filter interceptando request: {}", path);

        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            logger.info("Header Authorization detectado: {}", token);

            try {
                if (jwtService.validateToken(token)) {
                    String userId = jwtService.getUserIdFromToken(token).toString();
                    String email  = jwtService.getEmailFromToken(token);

                    logger.info("Token válido para userId={} email={}", userId, email);

                    request.setAttribute("userId", userId);
                    request.setAttribute("userEmail", email);

                } else {
                    logger.warn("Token inválido: {}", token);
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.getWriter().write("{\"error\":\"Token inválido\"}");
                    return;
                }
            } catch (Exception e) {
                logger.warn("Error validando JWT: {}", e.getMessage());
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().write("{\"error\":\"Excepción validando token\"}");
                return;
            }

        } else {
            logger.warn("Header Authorization faltante para endpoint {}", path);
            // Solo bloquear endpoints protegidos
            if (path.startsWith("/partida")) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().write("{\"error\":\"Authorization header faltante\"}");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}

