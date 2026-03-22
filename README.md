# Steam Database Project

## Overview

This project consists of a relational database developed in MySQL, designed to analyze trends in the video game market. The objective is to transform raw data into meaningful insights that support strategic decision-making for game development.

## Objectives

* Build a relational database from a real dataset
* Implement SQL objects such as views, functions, stored procedures, and triggers
* Generate analytical insights from stored data
* Identify trends in the video game market

## Database Structure

The database includes the following components:

* Core table: `games`
* Supporting tables: `game_tags`, `game_categories`
* Analytical tables:

  * `game_metrics` (calculated metrics)
  * `game_trends` (trend analysis)
* Classification tables:

  * `game_types`
  * `game_type_map`

## Key Features

### Metrics Calculation

* Approval percentage
* Estimated ownership
* Total reviews

### Trend Analysis

* Trend score calculation
* Popularity classification
* Success classification

### Market Segmentation

Games are classified into the following segments:

* Niche
* Mid Market
* High Market

## Analytical Insights

The system allows analysis of:

* Market distribution
* Game performance by segment
* Trends based on tags

## Technologies Used

* MySQL
* SQL

## Project Structure

* `sql/Steam_database_schema.sql` → Database structure
* `sql/Steam_database_data.sql` → Data loading and analysis

## Purpose

This project demonstrates how structured data can be used to analyze market behavior and support strategic decision-making in the video game industry.
