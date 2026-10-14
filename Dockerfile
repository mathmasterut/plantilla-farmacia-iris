# InterSystems IRIS Community Edition (gratuita, para desarrollo y aprendizaje)
FROM intersystemsdc/iris-community:latest

WORKDIR /home/irisowner/dev

# Copia el proyecto DENTRO del contenedor con el usuario de IRIS como dueno,
# asi los archivos se pueden editar y compilar sin problemas de permisos.
COPY --chown=irisowner:irisowner . /home/irisowner/dev

# Configuracion inicial: evita que las contrasenas de desarrollo expiren.
RUN iris start IRIS && \
    iris session IRIS < /home/irisowner/dev/iris.script && \
    iris stop IRIS quietly
