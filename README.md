# Real-Time Document Processing with Snowflake Streams + AI

A practical guide to building an intelligent file processing pipeline that processes PDFs the moment they're uploaded.

## The Pipeline

Upload PDF → Stream Detects → AI Extracts Text → Chunks Created → Search Ready (in ~30 seconds)

## Medium Blog Structure

**Single comprehensive article covering:**

- The file processing problem and why batch jobs fail
- How Streams + Cortex AI solve it instantly
- Complete walkthrough with real invoice PDFs
- Production tips and optimization

## What You'll Build

A working system that:

- 📄 **Detects uploaded PDFs instantly** using Snowflake Streams
- 🤖 **Extracts text with AI** using Cortex PARSE_DOCUMENT
- ✂️ **Intelligently chunks content** for optimal search
- 🔍 **Creates vector embeddings** for semantic search
- ⚡ **Processes in real-time** (30 seconds vs hours)

## Real Data Included

- 📋 5 sample invoice PDFs in `scripts/data/`
- 🎯 Complete setup scripts for the environment
- 🤖 Cortex AI integration for document parsing and search

## Quick Start

```bash
# Set up environment
cp .env.template .env
source .env
```

### Run setup

```bash
cd scripts/
./setup.sh
./pat.sh
```

## What Makes This Special

Unlike traditional ETL:

- ⚡ **Real-time processing** - Documents are processed as soon as they're uploaded
- 🧠 **AI-powered** - Uses Snowflake Cortex for parsing and embeddings
- 📈 **Scalable** - Streams automatically handle varying document volumes
- 🔄 **Self-healing** - Failed documents can be reprocessed automatically

## References

- [Introduction to Streams in Snowflake](https://docs.snowflake.com/en/user-guide/streams-intro)
- [Snowflake Cortex AI SQL Reference](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)
- [Snowflake Cortex Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview)
