import time
import threading

def cpu_intensive_task(task_id):
    iteration = 0
    while True:
        _ = [x**2 for x in range(10**6)]  # Simulate CPU-intensive computation
        iteration += 1
        print(f"Task {task_id}: Completed iteration {iteration}")  # Log progress
        time.sleep(1)  # Optional: Add a small delay to avoid flooding logs

def main():
    threads = []
    for i in range(4):  # Create 4 threads for parallel computation
        thread = threading.Thread(target=cpu_intensive_task, args=(i,))
        thread.start()
        threads.append(thread)
    for thread in threads:
        thread.join()

if __name__ == "__main__":
    print("CPU-intensive application started...")
    main()
