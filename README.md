
<div align="center">

<a href="https://github.com/pomarec/sangre">
  <img src="images/logo.png" alt="Logo" width="80" height="80">
</a>


Sangre provides a **generic solution** for **streaming complex backend queries** to clients in **realtime**.

[About The Project](#about-the-project) •
[How it works](#how-it-works) •
[Installation](#installation) •
[Contact](#contact) •
[Acknowledgments](#acknowledgments)


![Generic badge](https://img.shields.io/static/v1?label=Status&message=Alpha&color=orange&style=flat)
![Generic badge](https://img.shields.io/static/v1?label=Licence&message=GPLv3&color=green&style=flat)
![Generic badge](https://img.shields.io/static/v1?label=Contact&message=po@marec.me&color=blue&style=flat)


</div>

# About The Project

Sangre provides a generic solution for streaming complex backend queries to clients in realtime.

A complex query is an arbitrary nested query of structured database data and processing of this data in your native backend language (js, python, etc.)

The result of such query is streamed to client using incremental updates, minimizing network load, and enabling offline sync.

Typical use case is a client-server topology, a mobile or web app consuming an API (expressjs, django, rails, etc.) in front of a database (postgres, mongo, mysql, etc.). You want realtime data in your app withouh all the complexity of developing your own data sync.

Sangre implements all the following features and let the developers focus of business logic.

<div align="center">

| Features                           |  |
| -------------------------- | :----------------: |
| Realtime processing of relational database query + abitrary transformation           |         ✔️         |
| Client streaming over websocket           |         ✔️         |
| Offline sync for clients           |         ✔️         |
| Minimal network load (incremental updates)           |         ✔️         |
| Can be added to existing project           |         ✔️         |
</div>

# How it works (TODO)



# Installation (TODO)

*Note : only postgres supported ATM (more to come)*

todo

## 1. Enable postgres replication

```
ALTER SYSTEM SET wal_level = logical;
CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
```

## 2. Install realtime broker

```
insert supabase realtime installation steps
```



# Contact

[![Generic badge](https://img.shields.io/static/v1?label=Contact&message=po@marec.me&color=blue&style=flat)](mailto:po@marec.me)

Project Link: [https://github.com/pomarec/sangre](https://github.com/pomarec/sangre)


# Acknowledgments

 - <a href="https://www.flaticon.com/free-icons/blood" title="blood icons">Blood icons created by Freepik - Flaticon</a>
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
