dstream_clusterisation
======================

Aplikacja pozwala na klasteryzację danych zgodnie z algorytmem Dstream w wersji offline. Dane wejściowe (dowolnego wymiaru) dostarczane są w pliku wejściowym, który zostaje wczytany i wstępnie przetworzony przez moduł `offline_dstream`, a następnie sklasteryzowane przez drugi moduł `clusterisation`. W pliku wyjściowym wygenerowanym przez ostatni moduł znajdują się poszczególne rekordy podzielone na klastry.

Algorytm jest zaimplementowany w paradygmacie MapReduce i wykonuje się przy wykorzystaniu narzędzia [Apache Hadoop](http://hadoop.apache.org/), które jest konieczne do jego uruchomienia. W celu zwiększenia wydajności zaleca się uruchamianie go na rozproszonej architekturze, która umożliwia przetwarzanie równoległe.

# Zależności

Wymagane oprogramowanie:
* [Java](http://www.java.com/pl/)
* [Maven](http://maven.apache.org/)

Pozostałe dependencje zawarte są w plikach `pom.xml` i powinne zostać pobrane automatycznie podczas budowania projektu

# Budowanie i uruchamianie projektu

Aby zbudować i uruchomić program należy wykonać:

    ~$ git clone https://github.com/jstypka/dstream_clusterisation.git
    ~$ cd dsteam_clusterisation/
    ~$ git submodule foreach pull
    ~$ ./compile.sh
    
Projekt zostanie ściągnięty i zbudowany przez narzędzie Maven, a wszystkie dependencje powinne zostać ściągnięte z internetu.
W razie problemów ze skryptem `compile.sh` można również wywołać polecenie `mvn install` w folderach `clusterisation` oraz `mapreduce`, co powinno mieć podobny efekt.

# Opis algorytmu
