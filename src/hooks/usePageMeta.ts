import { useEffect } from 'react'

export default function usePageMeta(title?:string, description?:string){
  useEffect(()=>{
    if(title) document.title = title + ' — めざましリレー'
    if(description){
      let m = document.querySelector('meta[name="description"]')
      if(!m){ m = document.createElement('meta'); m.setAttribute('name','description'); document.head.appendChild(m) }
      m.setAttribute('content', description)
    }
  },[title,description])
}
