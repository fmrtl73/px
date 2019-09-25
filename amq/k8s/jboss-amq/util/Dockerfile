FROM openjdk:8-jre-alpine
COPY AMQUtil-300.jar /AMQUtil-300.jar
COPY AMQUtil-300.properties /AMQUtil-300.properties
ENTRYPOINT ["/usr/bin/java", "-jar", "AMQUtil-300.jar"]
CMD ["AMQUtil-300.properties"]
