# Сборка и установка пакетов под архитектуру aarch64


## Небольшое предисловие
Описание команд, которые могут пригодиться во время работы:

а. копирование по ssh на целевую платформу: 
    
    // копирование по ssh на целевую платформу
    scp путь_до_файла логин@ip_адресс:путь_назначения_на_платформе
    
b. запуск docker контейнера в фоне: 

    docker run --name <ID образа> имя_образа /bin/true
    
c. запуск docker контейнера с определенной командой:

    docker run -it имя_контейнера комманда
    
d. копирование из docker контейнера:

    docker cp <ID образа>:/work/имя_файла имя_файла

## OpenVINO (Для Intel Compute Stick)

### Требуемые пакеты (Их поставить просто через pip):
1) tensorflow-aarch64>=1.2.0
3) networkx>=1.11
4) numpy>=1.12.0
5) protobuf==3.6.1
6) test-generator==0.1.1
7) defusedxml>=0.5.0

### Inference-engine
OpenVINO официально не поддерживает arm64,только arm32. Но это не беда, так как arm64 умеет запускать arm32 приложения, поэтмоу сначала мы соберем кросс-компиляцией весь OpenVINO, а затем перекинем его на arm64 платформу (в моем случае – orangepi). Для кросс-компиляции будем использовать docker.
1) Скачайте репозиторий:
```
git clone https://github.com/au4lab/orangePi_neuralNetwork.git
cd orangePi_neuralNetwork
```
2) Там будет папка cross_OpenVINO. Запустите образ docker
```
docker image build -t ie_cross_armhf cross_openVINO/ 
```
Дождитесь сборки. Все собранные файлы лежат в директори /work/

Сейчас мы собрали inference-engine, что включает для себя все нужные библиотеки и файлы. Затем через ssh закидываем файл на arm64 платформу. 

### Model optimizer
Для конвертации популярных форматов обученных моделей нам потребуется собрать model optimizer.Если вам не требуются модели Mxnet, то шаг 1.3.1 можно пропустить, так как простым способом типа pip на arm64 Mxnet не поставить. А для сборки напрямую на платформе не хватает мощности. Поэтому используем кросс-компиляцию. 

### Mxnet
В уже скачанном вами репозитории есть папка cross_mxnet. 
```
cd cross_mxnet/
docker build -f Dockerfile.build.armv8 .
```
Дождитесь сборки. Все собранные файлы лежат в директори /work/
Затем перекиньте файлы на arm64 платформу через ssh

## Что делать с файлами на arm64 платформе
Сначала скопируйте их в любое удобное место, у меня это была директория Documents/. Затем нужно установить нужные пакеты, для того, чтобы приложения для архитектуры armhf (он же arm32) могли запускаться на aarch64. 
```
dpkg --add-architecture armhf
apt-get update
apt-get install libc6:armhf libstdc++6:armhf
```
Теперь, чтобы поставить какой-либо пакет для arm32 нам нужно после его названия писать :armhf. Также для нормальной работы OpenVINO с камерой нам понадобиться opencv 4.0, но собирать нам ее уже не надо будет, так как у intel есть Raspi Toolkit – еще один набор с нужными библиотеками (в том числе и opencv 4.0). Также при попытке запуска программ у нас может быть ошибка, что библиотеки не найдены, поэтому не забудьте добавить все файлы из inference-engine/lib директории в /usr/lib и usr/local/lib. 
Также для запуска нужно прописать настройку переменных    

## Создание окружения для компиляции программ с поддержкой openVINO
Так как собирать  программы прямо на платформе – идея не самая хорошая, так как компиляторы для arm64 не всегда могуть ужиться с компиляторами для arm32. Да, есть способы, типа chroot. Но  компилировать прямо на целевой платформе нет смысла из-за соображений производительности. К тому же как правило на релизной версии тулчейнов и копиляторов не содердится из-за соображений экономии памяти. Поэтому будем использовать docker. В скачанном вами репозитории есть папка openVINO_env. Проделайте следующее: 
```
docker build --rm -f "openVINO_env/Dockerfile" -t openvino_env:latest openVINO_env
```
Дождитесь сборки. Затем скопируйте архив. К тому же в данном контейнере вы получили окружение, где можно компилировать для openVINO. 

## ROS
Собирать будем из исходников 
```
sudo apt-get install python-rosdep python-rosinstall-generator python-wstool python-rosinstall build-essential
sudo rosdep init
rosdep update
```
Создадим рабочую директорию 
```
mkdir ~/ros_catkin_ws
cd ~/ros_catkin_ws
```
Ставить будем Bare-bone версию, так как графические пакеты не нужны 
```
rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall
wstool init -j8 src kinetic-ros_comm-wet.rosinstall
```
Ставим нужные зависимости 
```
rosdep install --from-paths src --ignore-src --rosdistro kinetic -y
```
Собираем 
```
./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release
```
После сборки может быть ошибка при запуске ROS комманд – permission denied. Чтобы это исправить:
```
sudo chmod -R 777 /home/orangepi/ros_catkin_ws/
sudo chmod -R 777 /home/orangepi/.ros/
```
Для загрузки setup`a:
```
source ~/ros_catkin_ws/install_isolated/setup.bash
```
