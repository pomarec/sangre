FROM dart:stable

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .

# We force serial test as they depend on the same database
CMD dart test --concurrency=1 