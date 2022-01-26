
<div align="center">

<a href="https://github.com/pomarec/sangre">
  <img src="doc/images/logo.png" alt="Logo" width="80" height="80">
</a>
<h2>Sangre</h2>
<br>

Sangre **streams your backend queries in realtime** to your clients minimizing the load via diffs.

Sangre lives with your current backend framework (expressjs, django, rails, etc.)

[About The Project](#about-the-project) •
[How it works](#how-it-works) •
[Installation](#installation) •
[Contact](#contact) •
[Acknowledgments](#acknowledgments)


![Generic badge](https://img.shields.io/static/v1?label=Status&message=Proof%20Of%20Concept&color=orange&style=flat)
![Generic badge](https://img.shields.io/static/v1?label=Licence&message=GPLv3&color=green&style=flat)
![Generic badge](https://img.shields.io/static/v1?label=Contact&message=po@marec.me&color=blue&style=flat)


</div>

# Example

This example is based on dart but feel free to imagine in your own language.

```dart
void main() async {
  final app = await setupMyApp(); // expressjs, django, rails

  // Setup node
  final followedNode = await DBNode('users').get('id', 1).joinMany(
        'followeds',
        fromNode: DBNode('users').joinMany(
          'places',
          fromNode: DBNode('places'),
        ),
      );

  // Plug the node to an endpoint
  app.sangre('/followeds', followedNode);

  await app.listen();
}
```

This exposes a websocket endpoint streaming the user (id==1) with its followed users populated with their places.

The websocket streams the updates as this data changes in the database.
See working example [here](example/).

# About The Project

Sangre provides a generic solution for streaming complex backend queries to clients in realtime.

A complex query is an arbitrary nested query of structured database data and processing of this data in your native backend language (js, python, etc.)

The result of such query is streamed to client using incremental updates, minimizing network load, and enabling offline sync.

Typical use case is a client-server topology, a mobile or web app consuming an API (expressjs, django, rails, etc.) in front of a database (postgres, mongo, mysql, etc.). You want realtime data in your app without all the complexity of developing your own data sync.

Sangre implements all the following features and let the developers focus on business logic.

<div align="center">

| Features                                                                   |    |
| -------------------------------------------------------------------------- | -- |
| Realtime processing of relational database query + abitrary transformation | ✔️ |
| Client streaming over websocket                                            | ✔️ |
| Offline sync for clients                                                   | ✔️ |
| Minimal network load (incremental updates)                                 | ✔️ |
| Can be embedded into an existing project                                   | ✔️ |
| You need to adopt a new database                                           | ❌ |

</div>

# How it works 

Sangre is an acyclic graph of operator nodes acting on data. This data flows in those nodes as streams of data for reactivness.

Nodes may be filters, joins, populators. Root nodes provide data from the underling database (typically postgres) and listen to changes (via supabase realtime) in order to spread them down the data flow. Leaf nodes are the endpoints consumed by client apps (via websocket).

<div align="center">
  <h3>
    Sangre data flow
    <img src="doc/charts/topology.mmd.svg"/>
  </h3>
</div>

# Limitations (PoC)

*Note:  Dart is temporary, TypeScript might be the final implementation. I just happened to have my head in Dart when starting the PoC.*

At this point, Sangre is just a PoC. A lot of shortcuts have been taken to produce a working example. Here are known limitations, if you think about any other, please reach me out via [my contact info](#contact).

| Limits to overcome                                       | Feasibility |
| -------------------------------------------------------- | :---------: |
| Horizontal scalability                                   |     ✔️      |
| Observability                                            |     ✔️      |
| Upqueries                                                |     ✔️      |
| Language agnostic (needs implementation in each)         |     ❌      |
| Strict consistency                                       |     ❌      |
| Parametrized queries                                     |     ✔️      |
| Share nodes between similar queries                      |     ✔️      |

Diff algorithm is currently JSON patch. This can be easily changed for a more readable or effecient one (myers, histogram, yours ?)

# Installation (TODO)

*Note : only postgres supported ATM (more to come)*

*Note : You can use .docker/docker-compose.yml to get a working example running*

## 1. Enable postgres replication

Run once on your postgres database :
```
ALTER SYSTEM SET wal_level = logical;
CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
```

## 2. Install realtime broker

Sangre uses [supabase/realtime](https://github.com/supabase/realtime/) to listen to database changes (insert/modify/delete of rows).

You can see details of its capabilities and installation process on their repo.

We give you an example of how to run it in docker compose :

```
  realtime:
    image: supabase/realtime
    environment:
      DB_HOST: <your_db_ip>
      DB_PASSWORD: <your_db_password>
      SECURE_CHANNELS: false
    ports:
      - 4000:4000
```

# Contact

[![Generic badge](https://img.shields.io/static/v1?label=Contact&message=po@marec.me&color=blue&style=flat)](mailto:po@marec.me)

Project Link: [https://github.com/pomarec/sangre](https://github.com/pomarec/sangre)


# Acknowledgments

- Inspirations :
  - [NoriaDB](https://github.com/mit-pdos/noria/) : Huge thanks to [Jon Gjengset](https://github.com/jonhoo) for clearing up my mind about this topic ([Whitepaper](https://www.usenix.org/conference/osdi18/presentation/gjengset)). Sangre is not an implementation of this paper though.
  - All the work done around materialized views and dataflows ([Raw list of sources](https://tartan-durian-108.notion.site/Pre-research-916a864988604fe2821d063321348a26))

- Supabase for their [realtime](https://github.com/supabase/realtime/) tool that transforms postgres replica "stream" to websocket events (easy to consume)

- Dart librairies :
  - alfred
  - dartz
  - json_patch
  - postgres
  - realtime_client
  - rxdart
  - web_socket_channel
  - flutter
  - flex_color_scheme
  - hovering

- <a href="https://www.flaticon.com/free-icons/blood" title="blood icons">Blood icons created by Freepik - Flaticon</a>