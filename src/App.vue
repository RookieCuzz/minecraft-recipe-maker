<template>
  <div class="app-container">
    <h1 class="title">⛏️ 我的世界合成配方制作工具</h1>
    
    <div class="main-content">
      <!-- 配方类型选择 -->
      <div class="control-panel">
        <div class="control-group">
          <label>配方类型：</label>
          <select v-model="recipeType">
            <option value="crafting">工作台合成</option>
            <option value="furnace">熔炉</option>
          </select>
        </div>
        
        <div class="control-group" v-if="recipeType === 'crafting'">
          <label>配方形状：</label>
          <select v-model="gridSize">
            <option value="3">3x3 (工作台)</option>
            <option value="2">2x2 (背包)</option>
          </select>
        </div>
      </div>

      <!-- 工作台合成区域 -->
      <div v-if="recipeType === 'crafting'" class="crafting-area">
        <div class="crafting-grid-container">
          <h3>配方输入</h3>
          <div class="crafting-grid" :class="'grid-' + gridSize" ref="craftingGrid">
            <div 
              v-for="i in gridSize * gridSize" 
              :key="i"
              class="grid-slot"
              @click="selectSlot(i - 1)"
              :class="{ active: selectedSlot === i - 1 }"
              @drop="handleImageDrop($event, i - 1, 'crafting')"
              @dragover="handleDragOver"
            >
              <img v-if="craftingSlots[i - 1].image" :src="craftingSlots[i - 1].image" class="slot-image" />
              <input 
                v-model="craftingSlots[i - 1].text" 
                @focus="selectedSlot = i - 1"
                placeholder="物品"
                maxlength="20"
                :class="{ 'has-image': craftingSlots[i - 1].image }"
              />
              <button v-if="craftingSlots[i - 1].image" @click.stop="removeImage(i - 1, 'crafting')" class="remove-img">×</button>
            </div>
          </div>
        </div>

        <div class="arrow">→</div>

        <div class="result-container">
          <h3>合成结果</h3>
          <div class="result-slot" @drop="handleImageDrop($event, null, 'result')" @dragover="handleDragOver">
            <img v-if="resultItem.image" :src="resultItem.image" class="slot-image" />
            <input 
              v-model="resultItem.text" 
              placeholder="结果物品"
              maxlength="20"
              :class="{ 'has-image': resultItem.image }"
            />
            <button v-if="resultItem.image" @click.stop="removeImage(null, 'result')" class="remove-img">×</button>
            <div class="count-input">
              <label>数量：</label>
              <input 
                type="number" 
                v-model.number="resultCount" 
                min="1" 
                max="64"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- 熔炉合成区域 -->
      <div v-else class="furnace-area">
        <div class="furnace-container" ref="furnaceGrid">
          <div class="furnace-input">
            <h3>原材料</h3>
            <div class="furnace-slot" @drop="handleImageDrop($event, null, 'furnace-input')" @dragover="handleDragOver">
              <img v-if="furnaceInput.image" :src="furnaceInput.image" class="slot-image" />
              <input v-model="furnaceInput.text" placeholder="输入物品" maxlength="20" :class="{ 'has-image': furnaceInput.image }" />
              <button v-if="furnaceInput.image" @click.stop="removeImage(null, 'furnace-input')" class="remove-img">×</button>
            </div>
          </div>

          <div class="arrow">→</div>

          <div class="furnace-output">
            <h3>烧炼结果</h3>
            <div class="furnace-slot" @drop="handleImageDrop($event, null, 'furnace-output')" @dragover="handleDragOver">
              <img v-if="furnaceOutput.image" :src="furnaceOutput.image" class="slot-image" />
              <input v-model="furnaceOutput.text" placeholder="结果物品" maxlength="20" :class="{ 'has-image': furnaceOutput.image }" />
              <button v-if="furnaceOutput.image" @click.stop="removeImage(null, 'furnace-output')" class="remove-img">×</button>
            </div>
          </div>
        </div>
      </div>

      <!-- 操作按钮 -->
      <div class="action-buttons">
        <button @click="clearRecipe" class="btn btn-clear">清空配方</button>
        <button @click="exportAsImage" class="btn btn-export">📸 导出配方图</button>
        <button @click="exportAsJSON" class="btn btn-json">💾 导出JSON</button>
      </div>

      <!-- JSON预览 -->
      <div class="json-preview" v-if="showJSON">
        <h3>配方JSON</h3>
        <pre>{{ recipeJSON }}</pre>
        <button @click="copyJSON" class="btn btn-copy">复制JSON</button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import html2canvas from 'html2canvas'

export default {
  name: 'App',
  setup() {
    const recipeType = ref('crafting')
    const gridSize = ref(3)
    const craftingSlots = ref(Array.from({ length: 9 }, () => ({ text: '', image: null })))
    const resultItem = ref({ text: '', image: null })
    const resultCount = ref(1)
    const selectedSlot = ref(-1)
    const furnaceInput = ref({ text: '', image: null })
    const furnaceOutput = ref({ text: '', image: null })
    const showJSON = ref(false)
    const craftingGrid = ref(null)
    const furnaceGrid = ref(null)

    const selectSlot = (index) => {
      selectedSlot.value = index
    }

    const clearRecipe = () => {
      const size = gridSize.value * gridSize.value
      craftingSlots.value = Array.from({ length: size }, () => ({ text: '', image: null }))
      resultItem.value = { text: '', image: null }
      resultCount.value = 1
      furnaceInput.value = { text: '', image: null }
      furnaceOutput.value = { text: '', image: null }
      selectedSlot.value = -1
    }

    const handleImageDrop = (event, index = null, type = 'crafting') => {
      event.preventDefault()
      const file = event.dataTransfer.files[0]
      if (file && file.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onload = (e) => {
          if (type === 'crafting') {
            craftingSlots.value[index].image = e.target.result
          } else if (type === 'result') {
            resultItem.value.image = e.target.result
          } else if (type === 'furnace-input') {
            furnaceInput.value.image = e.target.result
          } else if (type === 'furnace-output') {
            furnaceOutput.value.image = e.target.result
          }
        }
        reader.readAsDataURL(file)
      }
    }

    const handleDragOver = (event) => {
      event.preventDefault()
    }

    const removeImage = (index = null, type = 'crafting') => {
      if (type === 'crafting') {
        craftingSlots.value[index].image = null
      } else if (type === 'result') {
        resultItem.value.image = null
      } else if (type === 'furnace-input') {
        furnaceInput.value.image = null
      } else if (type === 'furnace-output') {
        furnaceOutput.value.image = null
      }
    }

    const recipeJSON = computed(() => {
      if (recipeType.value === 'crafting') {
        const pattern = []
        const size = gridSize.value
        for (let i = 0; i < size; i++) {
          let row = ''
          for (let j = 0; j < size; j++) {
            const slot = craftingSlots.value[i * size + j]
            row += slot.text ? slot.text.charAt(0).toUpperCase() : ' '
          }
          pattern.push(row)
        }

        const key = {}
        const usedItems = new Set()
        craftingSlots.value.forEach(slot => {
          const itemText = slot.text
          if (itemText && !usedItems.has(itemText)) {
            key[itemText.charAt(0).toUpperCase()] = { item: itemText }
            usedItems.add(itemText)
          }
        })

        return JSON.stringify({
          type: 'minecraft:crafting_shaped',
          pattern: pattern,
          key: key,
          result: {
            item: resultItem.value.text || 'minecraft:stone',
            count: resultCount.value
          }
        }, null, 2)
      } else {
        return JSON.stringify({
          type: 'minecraft:smelting',
          ingredient: {
            item: furnaceInput.value.text || 'minecraft:iron_ore'
          },
          result: furnaceOutput.value.text || 'minecraft:iron_ingot',
          experience: 0.7,
          cookingtime: 200
        }, null, 2)
      }
    })

    const exportAsImage = async () => {
      const element = recipeType.value === 'crafting' ? craftingGrid.value : furnaceGrid.value
      if (!element) return

      try {
        const canvas = await html2canvas(element, {
          backgroundColor: '#ffffff',
          scale: 2
        })
        
        const link = document.createElement('a')
        link.download = `minecraft-recipe-${Date.now()}.png`
        link.href = canvas.toDataURL()
        link.click()
      } catch (error) {
        alert('导出失败：' + error.message)
      }
    }

    const exportAsJSON = () => {
      showJSON.value = !showJSON.value
    }

    const copyJSON = () => {
      navigator.clipboard.writeText(recipeJSON.value)
        .then(() => alert('JSON已复制到剪贴板！'))
        .catch(() => alert('复制失败'))
    }

    return {
      recipeType,
      gridSize,
      craftingSlots,
      resultItem,
      resultCount,
      selectedSlot,
      furnaceInput,
      furnaceOutput,
      showJSON,
      craftingGrid,
      furnaceGrid,
      recipeJSON,
      selectSlot,
      clearRecipe,
      exportAsImage,
      exportAsJSON,
      copyJSON,
      handleImageDrop,
      handleDragOver,
      removeImage
    }
  }
}
</script>

<style scoped>
.app-container {
  background: white;
  border-radius: 16px;
  padding: 30px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.title {
  text-align: center;
  color: #333;
  margin-bottom: 30px;
  font-size: 32px;
}

.main-content {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.control-panel {
  display: flex;
  gap: 20px;
  justify-content: center;
  flex-wrap: wrap;
}

.control-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.control-group label {
  font-weight: bold;
  color: #555;
}

.control-group select {
  padding: 8px 15px;
  border: 2px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.crafting-area,
.furnace-area {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 40px;
  padding: 30px;
  background: #f8f9fa;
  border-radius: 12px;
}

.crafting-grid-container,
.result-container,
.furnace-container {
  display: flex;
  flex-direction: column;
  gap: 15px;
  align-items: center;
}

.crafting-grid {
  display: grid;
  gap: 8px;
  padding: 20px;
  background: #8b7355;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.grid-3 {
  grid-template-columns: repeat(3, 1fr);
}

.grid-2 {
  grid-template-columns: repeat(2, 1fr);
}

.grid-slot {
  width: 70px;
  height: 70px;
  background: #c6c6c6;
  border: 3px solid #555;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  overflow: hidden;
}

.grid-slot:hover {
  background: #d6d6d6;
  transform: scale(1.05);
}

.grid-slot.active {
  border-color: #4CAF50;
  box-shadow: 0 0 10px rgba(76, 175, 80, 0.5);
}

.grid-slot input {
  width: 100%;
  height: 100%;
  border: none;
  background: transparent;
  text-align: center;
  font-size: 12px;
  font-weight: bold;
  color: #333;
}

.grid-slot input:focus {
  outline: none;
}

.slot-image {
  position: absolute;
  width: 100%;
  height: 100%;
  object-fit: contain;
  pointer-events: none;
  z-index: 1;
}

.grid-slot input.has-image,
.result-slot input.has-image,
.furnace-slot input.has-image {
  position: absolute;
  bottom: 2px;
  font-size: 9px;
  background: rgba(0, 0, 0, 0.6);
  color: white;
  padding: 1px 3px;
  border-radius: 3px;
  z-index: 2;
  width: auto;
  max-width: 90%;
}

.remove-img {
  position: absolute;
  top: 2px;
  right: 2px;
  width: 18px;
  height: 18px;
  background: rgba(255, 0, 0, 0.8);
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  line-height: 1;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 3;
  transition: all 0.2s;
}

.remove-img:hover {
  background: rgba(255, 0, 0, 1);
  transform: scale(1.1);
}

.result-slot {
  width: 100px;
  height: 100px;
  background: #c6c6c6;
  border: 3px solid #555;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 10px;
  position: relative;
  overflow: hidden;
}

.result-slot input {
  width: 100%;
  border: none;
  background: transparent;
  text-align: center;
  font-size: 14px;
  font-weight: bold;
  color: #333;
}

.result-slot input:focus {
  outline: none;
}

.count-input {
  display: flex;
  align-items: center;
  gap: 5px;
  margin-top: 5px;
}

.count-input label {
  font-size: 11px;
  color: #333;
}

.count-input input {
  width: 40px;
  padding: 2px;
  text-align: center;
  font-size: 12px;
}

.arrow {
  font-size: 48px;
  color: #555;
  font-weight: bold;
}

.furnace-container {
  display: flex;
  gap: 40px;
  align-items: center;
}

.furnace-input,
.furnace-output {
  display: flex;
  flex-direction: column;
  gap: 15px;
  align-items: center;
}

.furnace-slot {
  width: 100px;
  height: 100px;
  background: #c6c6c6;
  border: 3px solid #555;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 10px;
  position: relative;
  overflow: hidden;
}

.furnace-slot input {
  width: 100%;
  height: 100%;
  border: none;
  background: transparent;
  text-align: center;
  font-size: 14px;
  font-weight: bold;
  color: #333;
}

.furnace-slot input:focus {
  outline: none;
}

.action-buttons {
  display: flex;
  gap: 15px;
  justify-content: center;
  flex-wrap: wrap;
}

.btn {
  padding: 12px 30px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-clear {
  background: #f44336;
  color: white;
}

.btn-clear:hover {
  background: #d32f2f;
  transform: translateY(-2px);
}

.btn-export {
  background: #4CAF50;
  color: white;
}

.btn-export:hover {
  background: #45a049;
  transform: translateY(-2px);
}

.btn-json {
  background: #2196F3;
  color: white;
}

.btn-json:hover {
  background: #0b7dda;
  transform: translateY(-2px);
}

.btn-copy {
  background: #FF9800;
  color: white;
  margin-top: 10px;
}

.btn-copy:hover {
  background: #f57c00;
}

.json-preview {
  background: #f5f5f5;
  padding: 20px;
  border-radius: 8px;
  border: 2px solid #ddd;
}

.json-preview h3 {
  margin-bottom: 15px;
  color: #333;
}

.json-preview pre {
  background: #282c34;
  color: #61dafb;
  padding: 15px;
  border-radius: 8px;
  overflow-x: auto;
  font-size: 14px;
  line-height: 1.5;
}

h3 {
  color: #555;
  font-size: 18px;
  text-align: center;
}
</style>
