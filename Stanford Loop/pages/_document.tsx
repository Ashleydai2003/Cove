import Document, { Html, Head, Main, NextScript } from 'next/document'

class MyDocument extends Document {
  render() {
    return (
      <Html>
        <Head>
          <link
            href="https://fonts.googleapis.com/css2?family=Libre+Bodoni:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500;1,600;1,700&display=swap"
            rel="stylesheet"
          />
        </Head>
        <body style={{ 
          margin: 0,
          padding: 0,
          backgroundColor: '#F5F0E6',
          minHeight: '100vh'
        }}>
          <Main />
          <NextScript />
        </body>
      </Html>
    )
  }
}

export default MyDocument 