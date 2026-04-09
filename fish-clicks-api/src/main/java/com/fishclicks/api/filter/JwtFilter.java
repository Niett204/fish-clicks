package com.fishclicks.api.filter;

import com.fishclicks.api.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtFilter.class);

    @Autowired
    private JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        String path = request.getRequestURI();

        // Evitar logs excesivos en rutas que no nos interesan
        if (!path.equals("/error")) {
            logger.info("JWT Filter interceptando request: {}", path);
        }

        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);

            try {
                if (jwtService.validateToken(token)) {
                    String userId = jwtService.getUserIdFromToken(token).toString();
                    String email  = jwtService.getEmailFromToken(token);

                    // 1. Guardar atributos para uso manual en controladores [cite: 15]
                    request.setAttribute("userId", userId);
                    request.setAttribute("userEmail", email);

                    // 2. NUEVO: Autenticar formalmente ante Spring Security
                    // Esto elimina el error 403 al llenar el contexto de seguridad
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userId, null, new ArrayList<>());

                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    // Establecemos la autenticación en el contexto global de la petición
                    SecurityContextHolder.getContext().setAuthentication(authToken);

                    logger.info("Token válido. Usuario {} autenticado correctamente", email);

                } else {
                    logger.warn("Token inválido detectado en: {}", path);
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json");
                    response.getWriter().write("{\"error\":\"Token inválido\"}");
                    return;
                }
            } catch (Exception e) {
                logger.error("Excepción al validar JWT: {}", e.getMessage());
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"Error en la validación del token\"}");
                return;
            }

        } else {
            // Si falta el header y la ruta es protegida, bloqueamos [cite: 15]
            if (path.startsWith("/partida")) {
                logger.warn("Acceso denegado: Falta Authorization header para ruta protegida: {}", path);
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"Authorization header faltante\"}");
                return;
            }
        }

        // Continuar con la cadena de filtros [cite: 15]
        filterChain.doFilter(request, response);
    }
}