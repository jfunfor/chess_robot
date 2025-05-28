# ChessRobot316
В этом моно-репозитории будут лежать все компоненты проекта, реализующего возможность игры в шахматы с помощью робота-манипулятора.

## Что реализовано сейчас?
В подпроекте mobile_and_desktop лежит клиент, реализованный с помощью кросс-платформенного фреймворка [Flutter](https://flutter.dev). (Документация - [README.MD](https://github.com/jfunfor/chess_robot/blob/main/mobile_and_desktop/README.md))          

В подпроекте backend лежит сервер, реализованный на Python, c БД Redis. Подключение к нему просиходит по WebSockets. А к роботу он подключается по TCP. (Документация - [README.MD](https://github.com/jfunfor/chess_robot/blob/main/backend/README.md))           

В подпроекте web лежит web-приложение, реализованное с помощью Vue.js.  (Документация - [README.MD](https://github.com/jfunfor/chess_robot/blob/main/web/README.md)) 


Проект развернут на сервере политеха на отдельной ВМ. (подробнее об этом можно прочитать [здесь](https://github.com/jfunfor/chess_robot/blob/main/deploy_chess.md)).




### Архитектура проекта выглядит следующим образом:
![Архитектура проекта](assets/architecture.png)

## Как взаимодействовать с роботом?
Подробная инструкция по взаимодействию с роботом представлена [здесь](https://github.com/jfunfor/chess_robot/blob/main/%D0%94%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D0%B0%D1%86%D0%B8%D1%8F_%D0%BF%D0%BE_%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D0%B5_%D1%81_%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%BE%D0%B9_%D0%B8_%D0%B2%D0%BA%D0%BB%D1%8E%D1%87%D0%B5%D0%BD%D0%B8%D0%B5%D0%BC_%D1%80%D0%BE%D0%B1%D0%BE%D1%82%D0%B0.pdf).
