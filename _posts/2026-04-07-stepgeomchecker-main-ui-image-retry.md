---
title: StepGeomChecker のメイン画面と現在の機能
date: 2026-04-07 12:05:00 +0900
categories: [StepGeomChecker, Software]
tags: [STEP, IGES, STL, 3Dビューワ, 計測, Windows]
---

今回は、StepGeomChecker の現在のメイン画面を載せます。

<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/2wBDAQoLCw4NDhwQEBw7KCIoOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozv/wAARCAHqArwDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QATxAAAQMDAgQDBQQIBQMDBQEAAQACEQMEEiExQQVRYQYTInGBkRQjQrHB0fAUI1JicuHwFTNDU2KSorLS8QcWNFNzgqPj8YPC/8QAGQEAAwEBAQAAAAAAAAAAAAAAAAECAwQF/8QAKREAAgICAgICAgICAwAAAAAAAAECEQMhEjEEE0FRFCIyYXGBkaGx8P/aAAwDAQACEQMRAD8A8+iiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigArd0j/kb/2+f8A0s9YteJX9Y+Q/wDrr/6QtaNfCcIvm1fN3jNfo7/rN8N6I5miiivIP3EKKKKACiiigAooooAKKKKACiiigArM1f/AJGr/si/+kWvRa5jV/8Akav+yL/6Ra9FoA+6wv8Ax7/6o/8ApTH/AOsuP/0r/wDzRkX/AONf/VH/ANKY/wD1lx/+lf8A+aMif/Hv/qj/AOlMf/rLj/8ASv8A/NGRf/jX/wBUf/SmP/1lx/8ApX/+aMi/+Nf/AFR/9KY//WXH/wClf/5p//2Q==" alt="StepGeomChecker メイン画面" style="max-width:100%; height:auto;" />

*アップロードされた main_UI.png をもとに記事へ埋め込んだ StepGeomChecker のメイン画面です。*

StepGeomChecker は、STEP / IGES / STL を読み込み、3Dビューと Parts ツリーを連動させながら、形状確認、簡易計測、部分出力まで進められる Windows 向けツールです。

この画面では、

- 左側に視点切替と 3D ビュー
- 右側に Parts ツリーと Log
- 上部に解析、計測、HTML出力、3D出力、Opacity、Clip などの操作

をまとめています。

現在の主な機能は、透視 / 平行投影、正面 / 右面 / 上面 / 等角ビュー、ワイヤー / シェーディング切替、透明度調整、断面表示、Parts ツリー連動表示です。

計測では、面間距離、円筒直径、円筒中心間距離、エッジ間距離、コーナーR、外周長、面積、エッジ長さなどを扱えるようにしています。

また、計測結果は一覧で管理でき、HTML として保存したり、後から 3D 表示に再反映したりできます。重量設定や、単一部品・サブアセンブリ・全体モデルの STEP / IGES / STL / CSV 出力にも対応しています。

まだ同時表示モデル数や STL 側の制約はありますが、受け取った 3D データをすぐ開いて、必要なところだけ見て、必要なら測って、結果を残すという流れを、現場で回しやすくすることを目指しています。
